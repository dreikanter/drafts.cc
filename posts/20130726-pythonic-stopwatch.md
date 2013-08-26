title: Pythonic stopwatch
created: 2013/07/26 17:53:33
tags: python, snippets

Себе на память.

<pre class="language-python prettyprint linenums">
import time
 
start_time = time.time()
time.sleep(1)
elapsed_time = time.time() - start_time
 
print(elapsed_time)
</pre>
