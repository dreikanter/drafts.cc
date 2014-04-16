title: Monosnap + Amazon S3
created: 2014/03/28 12:33:25
tags: aws, tools

Инструкци про то, как настроить [Monosnap](http://monosnap.com) для автоматического расшаривания скриншотов через [Amazon S3](http://aws.amazon.com/s3).

**Создаём бакет,** который будет виден из веба. Для этого отмечаем в его свойствах Enable website hosting, определяем Index Document значением `index.html`, и задаём permissions:

``` json
{
	"Version": "2008-10-17",
	"Statement": [
		{
			"Sid": "PublicReadGetObject",
			"Effect": "Allow",
			"Principal": {
				"AWS": "*"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::BUCKET_NAME/*"
		}
	]
}
```

Здесь и далее предполагается, что `BUCKET_NAME` — имя нашего бакета.

Если нет желания иметь дело с очень длинными ссылками на скриншоты (с доменом типа shots.drafts.cc.s3-website-eu-west-1.amazonaws.com), можно настроить более короткий доменный алиас: [Route 53 Hosted Zones](https://console.aws.amazon.com/route53/home#hosted-zones:) → Create hosted zone, и потом Create record set. Заводить отдельный домен для скриншотов чаще всего довольно бессмысленно, лучше создать субдомен для существующей зоны.

В форме создания новой DNS записи нужно сделать следующее:

1. Указать имя желаемого домена. В своём случае я сделал shots.drafts.cc в уже существовавшей зоне drafts.cc.
2. Определить тип записи — A.
3. В поле Alias задать значение Yes, и из списка доступных вариантов Alias target выбрать эндпоинт созданного ранее бакета.

Получиться должно примерно так:

![](http://media.drafts.cc/20140404165812.png)

**Создаём пользователя,** под которым Monosnap будет выкладывать скриншоты:  Security Credentials → [Users](https://console.aws.amazon.com/iam/home?#users) → Create New User. Не забываем скопировать или скачать Access Key ID и Secret Access Key (если этого не сделать, придётся создавать пользователя заново).

**Определяем права доступа к бакету.** В свойствах созданного пользователя открываем Permissions → Attach User Policy → Set Permissions → Custom Policy, и копируем туда это:

``` json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME",
      "Condition": {}
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectAclVersion"
      ],
      "Resource": "arn:aws:s3:::BUCKET_NAME/*",
      "Condition": {}
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*",
      "Condition": {}
    }
  ]
}
```

Скопировать готовый код гораздо проще, чем отмечать нужные чекбоксы в огромном списке.

**Настраиваем Monosnap.** Settings... → Account → Amazon S3:

![](http://media.drafts.cc/20140404164018.png)

В дополнение можно задать более компактный и нормально сортируемый формат имён файлов, например, `%Y%m%d%H%M%S`, и снять галку Short links. Если уж хостить скриншоты «у себя», то и от линки прямые давать более логично.
