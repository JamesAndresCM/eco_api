---
applyTo: "**/*.rb"
---
# Ruby 3 Coding Standards

## Language Features
- Use Ruby 3.x syntax and features extensively
- Leverage pattern matching with `case/in` for complex conditionals
- Use keyword arguments as default for method definitions
- Utilize frozen string literals with `# frozen_string_literal: true`
- Take advantage of endless method definitions for simple one-liners
- Use rightward assignment operator `=>` for pattern matching
- Implement proper error handling with specific exception types

## Method Definitions
- Prefer keyword arguments over positional arguments for clarity
- Use endless method syntax `def method_name = expression` for simple methods
- Always specify default values for optional keyword arguments
- Use double splat `**` for capturing additional keyword arguments
- Define private methods explicitly with `private` keyword
- Use descriptive method names that clearly indicate their purpose

## Pattern Matching
```ruby
# Use pattern matching for complex data structures
case user_data
in { name: String, age: Integer => age } if age >= 18
  create_adult_account(user_data)
in { name: String, age: Integer => age } if age < 18
  create_minor_account(user_data)
else
  raise InvalidUserDataError
end
```

## String and Symbol Usage
- Always use frozen string literals at the top of files
- Prefer symbols over strings for hash keys and constants
- Use string interpolation instead of concatenation
- Use %w[] for arrays of strings when appropriate
- Use heredocs for multi-line strings with proper indentation

## Error Handling
- Create custom exception classes inheriting from StandardError
- Use specific rescue blocks rather than catching all exceptions
- Implement proper error messages with context information
- Use `raise` without arguments to re-raise current exception
- Handle errors at appropriate abstraction levels

## Performance Optimizations
- Use `freeze` on constants and immutable objects
- Prefer `each` over `map` when return value is not needed
- Use `select` and `reject` instead of `filter` for clarity
- Implement lazy evaluation with `Enumerator::Lazy` for large datasets
- Cache expensive computations using memoization patterns

## Code Organization
- Group related constants at the top of classes
- Order methods logically: public, protected, private
- Use modules for shared functionality and namespacing
- Implement proper encapsulation with private/protected methods
- Keep classes focused on single responsibility

## Testing with Ruby 3
- Use Minitest as the default testing framework
- Write descriptive test method names starting with `test_`
- Use assert methods appropriate to the assertion type
- Implement proper setup and teardown for test isolation
- Test edge cases and error conditions explicitly

## Concurrency and Fiber
- Use Fiber for cooperative concurrency when appropriate
- Implement proper thread safety with Mutex when needed
- Avoid shared mutable state between threads
- Use Ractor for parallel execution with message passing
- Handle race conditions explicitly in concurrent code

## Memory Management
- Be mindful of object creation in loops
- Use string interpolation efficiently
- Implement proper cleanup in ensure blocks
- Monitor memory usage with appropriate profiling tools
- Use weak references when maintaining object caches
