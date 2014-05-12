title: Windows Software

# Windows Software Checklist

### General purpose

- Firefox ([extensions](/browser-extensions.html))
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
