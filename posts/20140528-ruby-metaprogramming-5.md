title: Ruby Object Model and Metaprogramming: Nine Examples
created: 2014/05/28 22:32:21
tags: ruby, конспекты

Продолжение [конспекта](/2014/05/26/ruby-metaprogramming-1.html) по курсу Дэйва Томаса.

---

Оглавление конспекта:

- Episode 1: [Objects and Classes](/2014/05/26/ruby-metaprogramming-1.html)
- Episode 2: [Sharing Behavior](/2014/05/26/ruby-metaprogramming-2.html)
- Episode 3: [Dynamic Code](/2014/05/28/ruby-metaprogramming-3.html)
- Episode 4: [instance_eval and class_eval](/2014/05/28/ruby-metaprogramming-4.html)
- **Episode 5: Nine Examples**
- Episode 6: Some Hook Methods
- Episode 7: More Hook Methods

---

Несколько примеров решения одной задачи — кэширования результата ресурсоёмкого вычисления (скидка для комбинации товаров).

### [1] Memoization

Прямолинейной подход, в котором результаты кэшируются в основном классе-вычислителе:

~~~ ruby
class Discounter
  def initialize
    @cache = {}
  end

  def discount(*items)
    unless @cache.has_key?(items)
      puts "Calculating discount for #{items}"
      @cache[items] ||= calculate_discount(*items)
    end
    @cache[items]
  end

  private

  def calculate_discount(*items)
    items.inject { |m, n| m + n }
  end
end

d = Discounter.new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
p d.discount(1, 2, 3)   # 6
p d.discount(4, 5, 6)   # Calculating discount for [4, 5, 6], 15
p d.discount(4, 5, 6)   # 15
~~~

Минус использования оператора `||=`, по сравнению с явной проверкой наличия ключа, в том, что нельзя кэшировать значение `nil`.

Второй минус в том, что кэширование захламляет основной код. В следующих примерах постараемся отделить одно от другого.

### [2] Using subclasses

Memoization можно убрать в класс-наследник, чтобы оно не шумело:

~~~ ruby
class Discounter
  def discount(*items)
    calculate_discount(*items)
  end

  private

  def calculate_discount(*items)
    puts "Calculating discount for #{items}"
    items.inject { |m, n| m + n }
  end
end

class MemoDiscounter < Discounter
  def initialize
    @cache = {}
  end

  def discount(*items)
    @cache[items] = super(*items) unless @cache.has_key?(items)
    @cache[items]
  end
end

d = MemoDiscounter.new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

Ещё одно улучшение в том, что вместо `||=` использована проверка `has_key?`.

### [3] Subclass with generator

Класс `MemoDiscounter` тривиален, и его можно сгенерировать автоматичеки:

~~~ ruby
class Discounter
  # ...
end

def memoize(cls, method)
  Class.new(cls) do
    cache = {}

    define_method(method) do |*args|
      cache[args] = super(*args) unless cache.has_key?(args)
      cache[args]
    end
  end
end

d = memoize(Discounter, :discount).new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

Обращаем внимание на то, что `cache` теперь не instance variable, а local variable. Так код ещё чище.

### [4] Using a ghost class

Есть ещё один вариант, как заинджектить кэширующую функцию в базовый класс:

~~~ ruby
class Discounter
  # ...
end

d = Discounter.new

def d.discount(*items)  # Создаётся ghost class, наследующий Discounter
  @cache ||= {}
  @cache[items] = super unless @cache.has_key?(items)
  @cache[items]
end

p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

Обращаем внимание на то, что вместо `super(*items)` можно использовать просто `super` (implicit argument passing!).

### [5] Ghost with generator

Звучит как «Приведение с мотором».

~~~ ruby
class Discounter
  # ...
end

def memoize(obj, method)
  ghost = class << obj
    self
  end
  ghost.class_eval do
    cache ||= {}
    define_method(method) do |*args|
      cache[args] = super(*args) unless cache.has_key?(args)
      cache[args]
    end
  end
end

d = Discounter.new
memoize(d, :discount)

p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

Implicit argument passing не поддерживается для динамически созданного таким способом метода, поэтому в `super` явно передаются аргументы `discount`.

Выражение `class << self` создаёт ghost class:

![](http://sh.drafts.cc/6x.jpg)

### [6] Rewrite the method

Пожалуй, самый кривой метод, который присутствует исключительно для полноты обзора возможностей.

~~~ ruby
class Discounter
  def discount(*items)
    calculate_discount(*items)
  end

  private

  def calculate_discount(*items)
    puts "Calculating discount for #{items}"
    items.inject { |m, n| m + n }
  end
end

class Discounter
  alias_method :_original_discount_, :discount
  def discount(*items)
    @cache ||= {}
    @cache[items] = _original_discount_(*items) unless @cache.has_key?(items)
    @cache[items]
  end
end

d = Discounter.new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

В Ruby можно «дописать» существующий класс повторно определив класс с тем же именем. Это не затрёт уже определённый класс, а будет работать примерно как partial в C#.

`alias_method` — метод, который есть в классах и модулях, позволяющий делать новые имена для существующих методов.

Конвенциональный underscore в начале строки означает don't mess with this. В Ruby есть приватные методы. Зачем нужна ещё дополнительная конвенция — не ясно.

### Rewriting using module

Самый хитрый способ: создаём модуль, и в этом модуле определяем метод, который сделает примерно то же, что было выполнено в примере [5]. Определит кэширующий метод вместо того, чьё имя мы зададим, а старый метод будет вызывать по алиасу.

~~~ ruby
module Memoize

  def remember(method)
    cache = {}
    original = "original_#{method}"
    alias_method original, method
    define_method(method) do |*args|
      cache[args] = send(original, *args) unless cache.has_key?(args)
      cache[args]
    end
  end

end

class Discounter
  extend Memoize

  def discount(*items)
    calculate_discount(*items)
  end

  remember :discount

  private

  def calculate_discount(*items)
    puts "Calculating discount for #{items}"
    items.inject { |m, n| m + n }
  end
end

d = Discounter.new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~

Имя алиаса может быть невалидным с точки зрения синтаксиса Ruby. Например, содержать пробел: `original = "original_#{method}"`. Метод по прежнему будет работать, но вызывать его можно будет только инвоками.

Для того, чтобы вызывать метод, используя его имя в виде строки, есть метод `send(method_name, *args)`.

### Write using bind

В предыдущем примере остаётся некрасивая деталь — алиас для проксирования вызовов оригинальному методу, чьи результаты надо кэшировать. Вместо алиаса можно сохранить метод в виде объекта. Для этого есть метод `Module#instance_method`, возвражающий объект-метод (`
UnboundMethod`) по заданному имени.

Для того, чтобы метод потом вызвать, его нужно привязать к инстансу класса (объект-метод — это действительно просто метод, а не указатель на метод существующего объекта). Для ассоциирования объекта-метода с инстансом, используется метод `UnboundMethod#bind`.

~~~ ruby
module Memoize
  def remember(method)
    original_method = instance_method(method)
    cache = {}
    define_method(method) do |*args|
      unless cache.has_key?(args)
        bound_method = original_method.bind(self)
        cache[args] = bound_method.call(*args)
      end
      cache[args]
    end
  end
end

class Discounter
  extend Memoize

  def discount(*items)
    calculate_discount(*items)
  end

  remember :discount

  private

  def calculate_discount(*items)
    puts "Calculating discount for #{items}"
    items.inject { |m, n| m + n }
  end
end
~~~

### Using DSL

Определяем метод `Memoize#remember` для определения кэширующегося метода в классе `Discounter`. Вторым аргументом в `define_method` можно передавать блок.

~~~ ruby
module Memoize
  def remember(method, &block)
    define_method(method, &block)
    original_method = instance_method(method)
    cache = {}
    define_method(method) do |*args|
      unless cache.has_key?(args)
        bound_method = original_method.bind(self)
        cache[args] = bound_method.call(*args)
      end
      cache[args]
    end
  end
end

class Discounter
  extend Memoize

  remember :discount do |*items|
    calculate_discount(*items)
  end

  private

  def calculate_discount(*items)
    puts "Calculating discount for #{items}"
    items.inject { |m, n| m + n }
  end
end

d = Discounter.new
p d.discount(1, 2, 3)   # Calculating discount for [1, 2, 3], 6
p d.discount(1, 2, 3)   # 6
~~~
