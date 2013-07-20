title: Killall for Windows
created: 2013/07/20 19:04:45
tags: windows, tips, command line

# Killall для Windows

Sublime Text — очень хороший редактор для кода, но в нём не хватает одной вещи: при запуске программы по <kbd>F7</kbd>, вышедший из под контроля процесс невозможно остановить средствами редактора. Для того чтобы остановить, например, такую программу, придётся открывать Task Manager и искать там процесс `python.exe`, полностью окупировавший одно процессорное ядро:

<pre class="languague-pyhton prettyprint linenums">
while True:
    pass
</pre>

Но этот метод не спортивен, особенно когда количество процессов умножается в геометрической прогрессии. Именно эта ситуация стала поводом для поиска некого аналога юниксового `killall` для Windows, под которым пока пориходится девелопить.

Как оказалось, тасккилл есть, и работает так:

<pre class="languague-css prettyprint linenums">
taskkill /f /t /im {process.exe}
</pre>

Здесь `/f` означает «force», `/t` говорит о необходимости останавливать и дочерние тоже, а `/im` задаёт имя процеса.

Процессы убиваются довольно быстро, хотя в моём случае, для того чтобы остановить несколько сотен запускающих самих себя `python.exe`, пришлось зупустить команду три раза.