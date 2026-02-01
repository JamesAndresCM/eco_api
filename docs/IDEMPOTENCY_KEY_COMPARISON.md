# Comparación: idempotency_key vs otras alternativas

## Problema a Resolver
Kafka reintenta el mensaje `orders.processed` porque el consumer tuvo un timeout. 
¿Cómo evitamos crear 2 pagos para la misma orden?

---

## Escenario 1: SIN idempotency_key

```ruby
def process_success(payload)
  order_id = payload["order_id"]
  user_id = payload["user_id"]
  
  # ¿Cómo sabemos si ya procesamos esto?
  # Opción A: Buscar por order_id
  payment = Payment.find_by(order_id: order_id)
  
  # PROBLEMA: ¿Y si el orden tiene múltiples pagos legítimos?
  # (ej: pago fallido, luego retry legítimo con nuevo carrito)
end
```

**Problemas**:
- ❌ No diferencia entre retry de mensaje vs retry legítimo del usuario
- ❌ Si usamos `order_id` único, bloqueamos pagos legítimos posteriores
- ❌ Race condition: dos consumers procesan al mismo tiempo

---

## Escenario 2: Usando transaction_token

```ruby
def process_success(payload)
  order_id = payload["order_id"]
  
  # Intentamos buscar por transaction_token... pero NO EXISTE AÚN
  payment = Payment.find_by(order_id: order_id)
  
  if payment.nil?
    payment = Payment.create!(order_id: order_id, ...)
    create_webpay_transaction  # Aquí se genera transaction_token
  end
end
```

**Problemas**:
- ❌ El `transaction_token` solo existe DESPUÉS de llamar a Webpay
- ❌ Si hay retry ANTES de llamar a Webpay → crea payment duplicado
- ❌ No previene el problema en el punto crítico

**Timeline**:
```
T1: Consumer 1 recibe mensaje → Payment.create! (id=100)
T2: Timeout antes de llamar Webpay
T3: Consumer reintenta → Payment.create! (id=101) ← DUPLICADO
T4: Ambos llaman a Webpay con transacciones diferentes
```

---

## Escenario 3: Usando transaction_reference

```ruby
def process_success(payload)
  # transaction_reference solo existe DESPUÉS del pago exitoso
  # En este punto del flujo, es SIEMPRE null
  # ❌ No sirve para detectar duplicados en creación
end
```

**Problema**:
- ❌ Solo existe después de `commit`
- ❌ Es útil en el controller, pero NO en el consumer

---

## Escenario 4: Usando public_id (UUID)

```ruby
def process_success(payload)
  order_id = payload["order_id"]
  user_id = payload["user_id"]
  
  # Generar UUID único
  public_id = SecureRandom.uuid
  
  payment = Payment.create!(
    public_id: public_id,
    order_id: order_id,
    ...
  )
end
```

**Problemas**:
- ❌ Cada retry genera UUID DIFERENTE
- ❌ No detecta que es el mismo order_id + user_id
- ❌ Crea payments duplicados

**Resultado**:
```
Retry 1: public_id = "abc-123" → Payment(id=1)
Retry 2: public_id = "def-456" → Payment(id=2) ← DUPLICADO
```

---

## Escenario 5: CON idempotency_key ✅

```ruby
def process_success(payload)
  order_id = payload["order_id"]
  user_id = payload["user_id"]
  
  # Generar clave DETERMINÍSTICA basada en los datos del mensaje
  idempotency_key = "payment:order:#{order_id}:user:#{user_id}"
  
  payment = IdempotentPaymentService.call(
    idempotency_key: idempotency_key,
    ...
  )
  
  # Si es retry → retorna el MISMO payment
  # Si es nuevo → crea uno nuevo
end
```

**Ventajas**:
- ✅ La clave es DETERMINÍSTICA (mismo input → misma clave)
- ✅ Existe ANTES de cualquier llamada externa
- ✅ Race condition protegida por índice UNIQUE en BD
- ✅ No depende de servicios externos (Webpay)

**Timeline**:
```
T1: Consumer 1 recibe mensaje → idempotency_key="payment:order:100:user:50"
T2: IdempotentService.call → Payment.create! (id=100)
T3: Timeout/error
T4: Consumer reintenta → MISMA idempotency_key="payment:order:100:user:50"
T5: IdempotentService.call → Payment.find_by(idempotency_key: ...) → retorna id=100
T6: ✅ No duplicado
```

---

## Comparación de Alternativas

| Alternativa | ¿Previene duplicados? | ¿Existe en creación? | ¿Determinístico? |
|------------|----------------------|---------------------|------------------|
| **idempotency_key** | ✅ Sí | ✅ Sí (lo generamos) | ✅ Sí |
| transaction_token | ❌ No | ❌ No (Webpay lo genera después) | ❌ No |
| transaction_reference | ❌ No | ❌ No (solo después del pago) | ❌ No |
| public_id (UUID) | ❌ No | ✅ Sí | ❌ No (aleatorio) |
| order_id único | ⚠️ Parcial | ✅ Sí | ✅ Sí |

### Problema con order_id único:
```ruby
# ¿Qué pasa si el usuario hace esto?
1. Agrega producto al carrito → order_id=100
2. Intenta pagar → Payment(order_id=100, status=failed)
3. Modifica carrito (agrega más productos)
4. Intenta pagar de nuevo → ❌ ERROR: order_id=100 ya existe

# Con idempotency_key:
1. order_id=100, cart_v1 → idempotency_key="payment:order:100:user:50:v1"
2. order_id=100, cart_v2 → idempotency_key="payment:order:100:user:50:v2"
```

---

## Clave: Determinismo

La diferencia fundamental es:

### ❌ NO Determinístico (UUID, tokens de Webpay)
```ruby
retry_1 = SecureRandom.uuid  # => "abc-123"
retry_2 = SecureRandom.uuid  # => "def-456"  ← DIFERENTE
# Cada retry genera valor distinto = no detecta duplicados
```

### ✅ Determinístico (idempotency_key)
```ruby
def generate_key(order_id, user_id)
  "payment:order:#{order_id}:user:#{user_id}"
end

retry_1 = generate_key(100, 50)  # => "payment:order:100:user:50"
retry_2 = generate_key(100, 50)  # => "payment:order:100:user:50"  ← IGUAL
# Mismo input = misma clave = detecta duplicados
```

---

## Conclusión

`idempotency_key` es necesario porque:

1. **Timing**: Existe ANTES de llamar a servicios externos
2. **Determinismo**: Mismo mensaje → misma clave
3. **Control**: Lo generamos nosotros, no depende de terceros
4. **Propósito específico**: Diseñado para deduplicación

`transaction_token` y `transaction_reference` tienen otros propósitos:
- `transaction_token`: Identificador de la transacción en Webpay
- `transaction_reference`: Código de autorización del pago

`public_id` podría servir solo si:
- Lo incluimos EN EL MENSAJE de Kafka (no lo generamos en consumer)
- El producer garantiza mismo public_id en retries
- Pero eso requiere cambiar toda la arquitectura del producer

**La solución con `idempotency_key` es la más robusta, simple y autocontenida.**
