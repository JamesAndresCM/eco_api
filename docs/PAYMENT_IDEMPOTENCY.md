# Implementación de Idempotencia en Pagos

## Resumen

Se ha implementado idempotencia en el sistema de pagos para evitar:
- Cobros duplicados
- Procesamiento múltiple de la misma transacción
- Problemas con reintentos de requests (ej: timeouts de red)
- Race conditions en el procesamiento de mensajes de Kafka

## Componentes Implementados

### 1. Migración de Base de Datos
- **Archivo**: `db/migrate/20260131000001_add_idempotency_key_to_payments.rb`
- **Cambios**: Agrega columna `idempotency_key` (string, única, indexada)
- **Ejecución**: `bin/rails db:migrate`

### 2. Modelo Payment
- **Archivo**: `app/models/payment.rb`
- **Validaciones**: Unicidad de `idempotency_key`
- **Scopes**: `idempotent(key)`, `completed`

### 3. Servicio de Idempotencia
- **Archivo**: `app/services/payments/idempotent_payment_service.rb`
- **Responsabilidad**: Crear pagos de forma idempotente
- **Manejo de race conditions**: Captura `ActiveRecord::RecordNotUnique`

### 4. Consumer de Kafka
- **Archivo**: `app/consumers/orders_processed_consumer.rb`
- **Clave de idempotencia**: `"payment:order:{order_id}:user:{user_id}"`
- **Comportamiento**: Solo crea transacción Webpay si es un pago nuevo

### 5. Controller de Webpay
- **Archivo**: `app/controllers/api/v1/payments/webpay_plus_controller.rb`
- **Validaciones**:
  - Estado del pago (paid/failed)
  - Código de autorización duplicado
  - Logging mejorado

## Flujo de Idempotencia

### Creación de Pago (Consumer)
```ruby
idempotency_key = "payment:order:123:user:456"
payment = IdempotentPaymentService.call(
  idempotency_key: idempotency_key,
  order_id: 123,
  user_id: 456,
  amount: 10000
)
```

**Escenarios**:
1. **Primera vez**: Crea nuevo payment y genera transacción Webpay
2. **Retry/Duplicado**: Retorna el payment existente, NO crea nueva transacción

### Confirmación de Pago (Controller)
**Validaciones en orden**:
1. Payment ya procesado (paid/failed) → retorna OK
2. Authorization code duplicado → retorna OK
3. Transaction válida → procesa normalmente

## Ventajas de la Implementación

### 1. **Seguridad en Reintentos**
Si el consumer de Kafka reintenta un mensaje (por timeout, fallo, etc), NO se creará un pago duplicado.

### 2. **Race Conditions**
Si dos procesos intentan crear el mismo pago simultáneamente, el índice único garantiza que solo uno tendrá éxito.

### 3. **Doble Confirmación**
El controller valida tanto el estado del payment como el authorization_code, evitando procesamiento duplicado.

### 4. **Auditabilidad**
Logging mejorado para rastrear pagos ya procesados.

## Ejemplo de Uso

### Caso 1: Procesamiento Normal
```
1. Consumer recibe mensaje: order_id=100, user_id=50
2. Genera key: "payment:order:100:user:50"
3. IdempotentPaymentService crea payment
4. Se crea transacción Webpay
5. Cliente paga
6. Controller confirma y actualiza payment a "paid"
```

### Caso 2: Retry del Consumer
```
1. Consumer recibe MISMO mensaje (retry): order_id=100, user_id=50
2. Genera MISMA key: "payment:order:100:user:50"
3. IdempotentPaymentService RETORNA payment existente
4. Detecta que ya tiene transaction_token → NO crea nueva transacción
5. Log: "Payment already processed or has transaction token"
```

### Caso 3: Doble Click en Confirmación
```
1. Webpay llama /commit con token_ws=ABC123
2. Controller procesa, actualiza payment a "paid"
3. Usuario refresca página (segunda llamada con MISMO token)
4. Controller detecta payment.status == "paid"
5. Retorna: "Payment already processed" (200 OK)
```

## Testing Recomendado

### Unit Tests
```ruby
# spec/services/payments/idempotent_payment_service_spec.rb
describe Payments::IdempotentPaymentService do
  it "creates payment on first call"
  it "returns existing payment on duplicate key"
  it "handles race conditions"
  it "raises error when idempotency_key is blank"
end
```

### Integration Tests
```ruby
# spec/consumers/orders_processed_consumer_spec.rb
describe OrdersProcessedConsumer do
  it "processes message only once with same idempotency key"
  it "creates Webpay transaction only for new payments"
end

# spec/requests/api/v1/payments/webpay_plus_spec.rb
describe "POST /api/v1/payments/webpay_plus/commit" do
  it "returns success on duplicate commit"
  it "detects duplicate authorization codes"
end
```

## Comandos de Deployment

```bash
# 1. Ejecutar migración
bin/rails db:migrate

# 2. Verificar en consola
bin/rails console
> Payment.column_names.include?("idempotency_key")
=> true

# 3. Rollback si es necesario
bin/rails db:rollback
```

## Monitoreo

### Queries útiles para verificar idempotencia:
```ruby
# Verificar pagos duplicados (antes de implementación)
Payment.group(:order_id, :user_id)
       .having("COUNT(*) > 1")
       .count

# Verificar pagos con idempotency_key
Payment.where.not(idempotency_key: nil).count

# Buscar retries detectados en logs
# "Payment already processed or has transaction token"
```

## Consideraciones Adicionales

### ¿Qué pasa si cambia el monto?
Si un order_id tiene diferentes montos (caso raro), el sistema usará la MISMA idempotency_key y retornará el primer pago creado. Esto es **intencional** para evitar cobros duplicados.

### ¿Cuánto tiempo mantener la clave?
Las claves de idempotencia se mantienen permanentemente en este diseño. Para cleanup, se podría:
- Eliminar claves de pagos antiguos (>90 días)
- Usar una tabla separada con TTL

### Alternativas consideradas
1. **UUID en mensaje Kafka**: Requiere modificar el producer
2. **Distributed locks (Redis)**: Mayor complejidad operacional
3. **Database locks**: Puede causar contención

La solución implementada es simple, robusta y no requiere dependencias adicionales.
