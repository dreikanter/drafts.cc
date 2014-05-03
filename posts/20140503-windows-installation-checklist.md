title: Windows Installation Checklist
created: 2014/05/03 17:56:49
tags: tech stuff, windows

В чеквисте образовался список того, что мне на текущий момент нужно на рабочей машине под Windows. Для OS X такого списка пока нет, но кажется, что он должен быть короче где-то на треть.

Постоянный адрес списка: [http://drafts.cc/windows-software.html](http://drafts.cc/windows-software.html) (если будут апдейты, то там).

### General purpose

- Firefox
    - 1Password extension
    - Ghostery
    - Flashblock
    - Hola
- 1Password
- Skype
- Telegram
- Dropbox
- [Typography Layout](http://ilyabirman.ru/projects/typography-layout/)
- Kaspersky Antivirus
- 7Zip
- Foobar2000 (use preconfigured from Dropbox)
- FastStone Image Viewer
- FastStone Capture
- Monosnap (use S3 for screenshots sharing)
- M-Audio MobilePre Driver
- VLC
- Mp3tag
- Pandoc
- Acronis True Image
- Chrome
- Yandex Disk
- Flash plugin
- Adobe Reader
- CCleaner
- King Office

### Work

- Sublime Text
- Far
- Ruby
- Python
- VirtualBox

### Don't install until really really needed (After system snapshot!)

- Microsoft Office
- iTunes
- Evernote
- Photoshop
- Visual Studio

### Things to do

- Make system snapshot with Acronis True Image
- Setup GitHub passwordless access
- Setup Windows backup
- Schedule backups for the archive
- Make directory joints
    - `mklink /j c:\users\alex\desktop\Dropbox d:\Dropbox`
    - `mklink /j c:\ruby\current c:\ruby\2.0.0`
    - `mklink /j c:\python\current c:\python\3.4`
    - `mklink /j "%APPDATA%\Sublime Text 3\Packages\User" "D:\src\dotfiles\win\sublime\User"`
    - `mklink /j c:\bin d:\Dropbox\bin`
- Add to `%PATH%`
    - `c:\git\bin`
    - `c:\python\current`
    - `c:\python\current\scripts`
    - `c:\ruby\current\bin`
    - `c:\ruby\devkit`
    - `c:\bin`
