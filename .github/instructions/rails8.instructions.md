---
applyTo: "**/*.rb"
---
# Rails 8 Coding Standards

## Framework Best Practices
- Use Rails 8 features like Solid Queue for background job processing
- Follow Rails conventions for naming and file organization
- Use ActiveModel attributes API for defining model attributes
- Use Rails built-in testing tools (Minitest) for all test cases
- Use SQLite for development and production environments

## Rails Controllers
- Keep controllers thin, focused on HTTP concerns
- Use strong parameters for all user input
- Prefer redirect_to with notice/alert over render for form submissions
- Use before_action filters for authentication and shared setup
- Respond to appropriate formats (HTML, Turbo Stream, JSON)

## Rails Models
- Use Rails validations extensively to ensure data integrity
- Add custom validation methods when built-in validators aren't sufficient
- Keep model callbacks minimal and consider service objects for complex logic
- Use scopes for common queries that return ActiveRecord::Relation
- Implement proper associations with dependent options

## Import Maps
- Use Import Maps for JavaScript dependencies
- Keep import map entries in `config/importmap.rb`
- Import JavaScript modules using ESM imports
- Pin external dependencies with specific versions
- Organize JavaScript code in modular files under app/javascript

## ActiveJob and Solid Queue
- Create dedicated job classes that inherit from ApplicationJob
- Keep jobs idempotent when possible
- Use meaningful queue names based on purpose
- Set appropriate retry behavior for each job
- Use perform_later for background processing

## Service Objects
- Create services that inherit from ApplicationService with class method `.call`
- Implement `initialize` method to receive parameters
- Implement abstract `call` method that must be defined in each service
- Keep services focused on a single responsibility
- Use services for complex business logic that doesn't belong in models or controllers
- Place services in `app/services/` with clear folder structure
- Handle errors consistently using exceptions or result objects
- Write unit tests for each service independently
- Use services for operations involving multiple models
- Avoid side effects in services; prefer returning explicit values