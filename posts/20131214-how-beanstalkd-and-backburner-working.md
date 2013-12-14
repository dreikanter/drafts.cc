title: Простой пример очереди задач
created: 2013/12/14 23:04:35
tags: distributed everything, ruby, как всё работает

Жил-был REST сервис, который принимал запросы и выполнял задачи. И всё бы ничего, но исполнение задач занимало относительно много времени, из-за чего нетерпеливые клиенты хмурились и отваливались по таймауту. Для того чтобы облегчить сервису работу, было решено убрать из него непосредственное исполнение задач в фоновые процессы, а сам сервис использовать только для того, чтобы ставить запросы в очередь.

Этот пост содержит пример того, как можно организовать такую очередь на Руби, с помощью [beanstalkd](http://kr.github.io/beanstalkd/) и джема [backburner](https://github.com/nesquena/backburner).

Репозиторий backburner содержит несколько готовых примеров, но мне не понравилось то, что в каждом из них генератор и исполнитель задач работают в рамках одного скрипта, из-за чего примеры выглядят искусственно.

Мне было нужно вынести исполнение долгих задач из веб-сервиса, работающего на Sinatra в отдельный процесс. Ниже по тексту — результат экспериментов — скрипт-генератор задач и скрипт-исполнитель, использующие общую конфигурацию.

Пример предполагает, что beanstalkd уже установлен и работает с дефолтными настройками на локальной машине. И джем backburner так же присутствует.

### `lib/init.rb`

Конфигурация backburner, общая для генератора задач и воркера.

```ruby
require 'backburner'

Backburner.configure do |config|
  config.beanstalk_url    = ['beanstalk://127.0.0.1']
  config.tube_namespace   = 'frank'
  config.on_error         = lambda { |e| logger.error e }
  config.primary_queue    = 'frank-jobs'
end
```

### `lib/job.rb`

Класс, имплементируюший задачу, — некую процедуру, исполнение которой занимает продолжительное время.

```ruby
class UberJob
  include Backburner::Queue

  def self.perform(value)
    10.times do |i|
      puts "Job #{value}, stage #{i}"
      sleep 0.5
    end
  end
end
```

### `prod.rb`

Скрипт, добавляющий новые задачи в очередь исполнения.

```ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'backburner'
require 'init'
require 'job'

job_id = Random.rand(100)
Backburner.enqueue UberJob, job_id
puts "Job #{job_id} enqeueud"
```

### `worker.rb`

Фоновый процесс, который последовательно исполняет задачи.

```ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'backburner'
require 'init'
require 'job'

Backburner.work
```

### Запускаем!

В левой панели консоли непрерывно работает исполнитель задач  `worker.rb`, в правой — многократно запускается скрипт `prod.rb`, добавляющий в очередь новые задачи со случайным ID.

![](http://media.drafts.cc/beanstalkd-backburner-example-1.png)

Посмотрим, что будет, если прерываем работу воркера по `Ctrl-C`, и запустить скрипт снова.

![](http://media.drafts.cc/beanstalkd-backburner-example-2.png)

Обработка очереди задач продолжается.
