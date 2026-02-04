# Design Patterns

Project-agnostic reference for common software design patterns.

---

## Creational Patterns

Patterns for object creation mechanisms.

### Singleton
Ensures a class has only one instance with global access point.

```typescript
class Logger {
  private static instance: Logger;

  private constructor() {}

  static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }
}
```

**Use when**: Single shared resource (config, connection pool, logger).
**Avoid when**: Testing requires isolation, or multiple instances may be needed.

### Factory Method
Defines interface for creating objects, letting subclasses decide which class to instantiate.

```typescript
interface Notification {
  send(message: string): void;
}

class EmailNotification implements Notification {
  send(message: string) { /* email logic */ }
}

class SMSNotification implements Notification {
  send(message: string) { /* SMS logic */ }
}

function createNotification(type: 'email' | 'sms'): Notification {
  switch (type) {
    case 'email': return new EmailNotification();
    case 'sms': return new SMSNotification();
  }
}
```

**Use when**: Object creation logic is complex or varies by context.

### Builder
Separates complex object construction from representation.

```typescript
class QueryBuilder {
  private query: QueryConfig = {};

  select(fields: string[]) {
    this.query.fields = fields;
    return this;
  }

  where(condition: Condition) {
    this.query.conditions.push(condition);
    return this;
  }

  limit(n: number) {
    this.query.limit = n;
    return this;
  }

  build(): Query {
    return new Query(this.query);
  }
}

// Usage
const query = new QueryBuilder()
  .select(['name', 'email'])
  .where({ field: 'active', value: true })
  .limit(10)
  .build();
```

**Use when**: Object has many optional parameters or complex construction.

### Dependency Injection
Provides dependencies from external sources rather than hard-coding.

```typescript
// Without DI - tightly coupled
class UserService {
  private db = new PostgresDatabase();
}

// With DI - loosely coupled
class UserService {
  constructor(private db: Database) {}
}

// Caller controls the dependency
const service = new UserService(new PostgresDatabase());
const testService = new UserService(new MockDatabase());
```

**Use when**: Need testability, flexibility, or adherence to DIP.

---

## Structural Patterns

Patterns for composing classes and objects.

### Adapter
Converts interface of a class into another interface clients expect.

```typescript
// Legacy API returns XML
interface LegacyAPI {
  getDataXML(): string;
}

// New code expects JSON
interface ModernAPI {
  getData(): object;
}

class LegacyAdapter implements ModernAPI {
  constructor(private legacy: LegacyAPI) {}

  getData(): object {
    const xml = this.legacy.getDataXML();
    return parseXMLtoJSON(xml);
  }
}
```

**Use when**: Integrating incompatible interfaces or legacy code.

### Decorator
Adds responsibilities to objects dynamically without modifying their structure.

```typescript
interface DataSource {
  read(): string;
  write(data: string): void;
}

class FileDataSource implements DataSource {
  read() { /* read from file */ }
  write(data: string) { /* write to file */ }
}

class EncryptionDecorator implements DataSource {
  constructor(private wrapped: DataSource) {}

  read() {
    return decrypt(this.wrapped.read());
  }

  write(data: string) {
    this.wrapped.write(encrypt(data));
  }
}

// Usage - compose behaviors
const source = new EncryptionDecorator(
  new CompressionDecorator(
    new FileDataSource()
  )
);
```

**Use when**: Need to add behavior without subclassing or modifying existing code.

### Facade
Provides simplified interface to complex subsystem.

```typescript
class VideoConverter {
  convert(filename: string, format: string): File {
    const file = new VideoFile(filename);
    const codec = CodecFactory.extract(file);
    const result = BitrateReader.read(file, codec);
    const converted = AudioMixer.fix(result);
    return new File(converted, format);
  }
}

// Client uses simple interface
const converter = new VideoConverter();
const mp4 = converter.convert('video.ogg', 'mp4');
```

**Use when**: Simplifying complex library/subsystem usage.

### Proxy
Provides surrogate or placeholder to control access to another object.

```typescript
interface Image {
  display(): void;
}

class RealImage implements Image {
  constructor(private filename: string) {
    this.loadFromDisk(); // Expensive operation
  }

  display() { /* render image */ }
}

class ProxyImage implements Image {
  private realImage: RealImage | null = null;

  constructor(private filename: string) {}

  display() {
    if (!this.realImage) {
      this.realImage = new RealImage(this.filename); // Lazy load
    }
    this.realImage.display();
  }
}
```

**Use when**: Lazy initialization, access control, logging, or caching.

---

## Behavioral Patterns

Patterns for communication between objects.

### Strategy
Defines family of algorithms, encapsulates each one, makes them interchangeable.

```typescript
interface PaymentStrategy {
  pay(amount: number): void;
}

class CreditCardPayment implements PaymentStrategy {
  pay(amount: number) { /* credit card logic */ }
}

class PayPalPayment implements PaymentStrategy {
  pay(amount: number) { /* PayPal logic */ }
}

class ShoppingCart {
  constructor(private paymentStrategy: PaymentStrategy) {}

  checkout(amount: number) {
    this.paymentStrategy.pay(amount);
  }
}

// Usage - strategy is interchangeable
const cart = new ShoppingCart(new CreditCardPayment());
cart.checkout(100);
```

**Use when**: Multiple algorithms for same task, need runtime switching.

### Observer
Defines one-to-many dependency so when one object changes state, dependents are notified.

```typescript
interface Observer {
  update(data: any): void;
}

class EventEmitter {
  private observers: Observer[] = [];

  subscribe(observer: Observer) {
    this.observers.push(observer);
  }

  notify(data: any) {
    this.observers.forEach(o => o.update(data));
  }
}

// Usage
const emitter = new EventEmitter();
emitter.subscribe({ update: (data) => console.log('Received:', data) });
emitter.notify({ event: 'user_created' });
```

**Use when**: State changes need to trigger updates in other objects.

### Command
Encapsulates request as object, enabling parameterization and queuing.

```typescript
interface Command {
  execute(): void;
  undo(): void;
}

class AddTextCommand implements Command {
  constructor(private editor: Editor, private text: string) {}

  execute() {
    this.editor.insert(this.text);
  }

  undo() {
    this.editor.delete(this.text.length);
  }
}

class CommandHistory {
  private history: Command[] = [];

  execute(command: Command) {
    command.execute();
    this.history.push(command);
  }

  undo() {
    const command = this.history.pop();
    command?.undo();
  }
}
```

**Use when**: Need undo/redo, queuing, or logging of operations.

### Chain of Responsibility
Passes request along chain of handlers until one handles it.

```typescript
interface Handler {
  setNext(handler: Handler): Handler;
  handle(request: Request): Response | null;
}

abstract class BaseHandler implements Handler {
  private next: Handler | null = null;

  setNext(handler: Handler): Handler {
    this.next = handler;
    return handler;
  }

  handle(request: Request): Response | null {
    if (this.next) {
      return this.next.handle(request);
    }
    return null;
  }
}

// Usage - chain handlers
const handler = new AuthHandler();
handler
  .setNext(new ValidationHandler())
  .setNext(new BusinessLogicHandler());

handler.handle(request);
```

**Use when**: Multiple handlers may process a request, order matters.

---

## Pattern Selection Guide

| Need | Consider |
|------|----------|
| Single shared instance | Singleton |
| Complex object creation | Factory, Builder |
| Testability, loose coupling | Dependency Injection |
| Interface incompatibility | Adapter |
| Add behavior dynamically | Decorator |
| Simplify complex API | Facade |
| Lazy loading, access control | Proxy |
| Interchangeable algorithms | Strategy |
| Event-driven updates | Observer |
| Undo/redo, operation logging | Command |
| Request processing pipeline | Chain of Responsibility |
