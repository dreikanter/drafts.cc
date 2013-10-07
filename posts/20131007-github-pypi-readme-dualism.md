title: Readme markup dualism
created: 2013/10/07 18:54:26
tags: github, python, english

Let's say we have a project hosted on GitHub. And this project is a python package supposed to be deployed on PyPI, so it includes `setup.py` defining all required metadata such as author name, license type, classifiers, and so on.

There is `long_description` among other `setup()` parameters. This value will be used by server to display on package home page. And there is a common practice to populate the package description with `README` file contents.

But what if your readme file uses markdown instead of reStructuredText—the only supported format on PyPI? And what if you don't want to change the markup? Not because GitHub wont understand it—RST is supported, the same way as eleventyseven [other markups](https://github.com/github/markup)—but for some different reason. For instance the reason that you prefer markdown syntax, and want to use it everywhere.

<big>In other words, how to keep project readme in markdown, and get PyPI to understand it properly?</big>

The solution is to convert readme markup on the fly, right before using it:

``` python
import subprocess as sp

def get_desc(file_name):
    cmd = "pandoc --from=markdown --to=rst %s" % file_name
    with sp.Popen(cmd, stdout=sp.PIPE, stderr=sp.PIPE) as process:
        return process.stdout.read().decode('utf-8')

setup(
    name='packagename',
    description='Yet another awesome package.',
    long_description=get_desc('README.md'),
    # other parameters are skipped
)
```

For sure this is a very simplified implementation, introducing a "hidden" dependency—pandoc tool. It would be nice to handle a situation when it's not available, and notify the user by a readable message instead of exception stack trace. But the purpose of this code is to illustrate the idea.

And here is the result: [https://pypi.python.org/pypi/publicstatic](https://pypi.python.org/pypi/publicstatic).
