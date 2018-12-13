require 'package'

class Sommelier < Package
  description 'Sommelier works by redirecting X11 and Wayland programs to the built-in ChromeOS wayland server.'
  homepage 'https://chromium.googlesource.com/chromiumos/containers/sommelier'
  version '1382ce084c'
  source_url 'https://chromium.googlesource.com/chromiumos/containers/sommelier/+/0.20/README?format=TEXT'
  source_sha256 'b58d799b16d20abf92369fe0749c73f7398996f0afa9933517051778a8bb16c3'

  binary_url ({
  })
  binary_sha256 ({
  })

  depends_on 'mesa'
  depends_on 'xkbcomp'
  depends_on 'xwayland'
  depends_on 'psmisc'

  def self.build
    system 'git clone https://chromium.googlesource.com/chromiumos/containers/sommelier'
    Dir.chdir ("sommelier") do
      system "git reset --hard 1382ce084cc40790340d672e8b62ec47733cb860"
      system "sed -i 's,/lib/,/#{ARCH_LIB}/,g' Makefile"
      system "sed -i 's,-I.,-I. -I#{CREW_PREFIX}/include/pixman-1,g' Makefile"
      system "make PREFIX=#{CREW_PREFIX} SYSCONFDIR=#{CREW_PREFIX}/etc"
      system "echo 'GDK_BACKEND=wayland' > .sommelier.env"
      system "echo 'CLUTTER_BACKEND=wayland' >> .sommelier.env"
      system "echo 'XDG_RUNTIME_DIR=/var/run/chrome' >> .sommelier.env"
      system "echo 'WAYLAND_DISPLAY=wayland-0' >> .sommelier.env"
      system "echo 'DISPLAY=:0' >> .sommelier.env"
      system "echo 'SCALE=1' >> .sommelier.env"
      system "echo '#!/bin/bash' > sommelierd"
      system "echo 'sommelier -X --x-display=\$DISPLAY --scale=\$SCALE --no-exit-with-child /bin/sh -c \"#{CREW_PREFIX}/etc/sommelierrc\"' >> sommelierd"
      system "echo '#!/bin/bash' > initsommelier"
      system "echo 'SOMM=\$(pidof sommelier 2> /dev/null)' >> initsommelier"
      system "echo 'if [ -z \"\$SOMM\" ]; then' >> initsommelier"
      system "echo '  [ -f #{CREW_PREFIX}/bin/stopbroadway ] && stopbroadway' >> initsommelier"
      system "echo '  #{CREW_PREFIX}/sbin/sommelierd &' >> initsommelier"
      system "echo '  sleep 3' >> initsommelier"
      system "echo 'fi' >> initsommelier"
      system "echo 'SOMM=\$(pidof sommelier 2> /dev/null)' >> initsommelier"
      system "echo 'if [ ! -z \"\$SOMM\" ]; then' >> initsommelier"
      system "echo '  echo \"sommelier process \$SOMM is running\"' >> initsommelier"
      system "echo 'else' >> initsommelier"
      system "echo '  echo \"sommelier failed to start\"' >> initsommelier"
      system "echo '  exit 1' >> initsommelier"
      system "echo 'fi' >> initsommelier"
      system "echo '#!/bin/bash' > stopsommelier"
      system "echo 'SOMM=\$(pidof sommelier 2> /dev/null)' >> stopsommelier"
      system "echo 'if [ ! -z \"\$SOMM\" ]; then' >> stopsommelier"
      system "echo '  sudo killall sommelier' >> stopsommelier"
      system "echo '  sleep 3' >> stopsommelier"
      system "echo 'fi' >> stopsommelier"
      system "echo 'SOMM=\$(pidof sommelier 2> /dev/null)' >> stopsommelier"
      system "echo 'if [ -z \"\$SOMM\" ]; then' >> stopsommelier"
      system "echo '  echo \"sommelier process stopped\"' >> stopsommelier"
      system "echo 'else' >> stopsommelier"
      system "echo '  echo \"sommelier process \$SOMM is running\"' >> stopsommelier"
      system "echo '  exit 1' >> stopsommelier"
      system "echo 'fi' >> stopsommelier"
    end
  end

  def self.install
    Dir.chdir ("sommelier") do
      system "make", "PREFIX=#{CREW_PREFIX}", "SYSCONFDIR=#{CREW_PREFIX}/etc", "DESTDIR=#{CREW_DEST_DIR}", "install"
      system "install -Dm755 sommelierd #{CREW_DEST_PREFIX}/sbin/sommelierd"
      system "install -Dm755 initsommelier #{CREW_DEST_PREFIX}/bin/initsommelier"
      system "install -Dm755 stopsommelier #{CREW_DEST_PREFIX}/bin/stopsommelier"
      system "install -Dm644 .sommelier.env #{CREW_DEST_HOME}/.sommelier.env"
      system "cp .sommelier.env ~/"
    end
  end

  def self.postinstall
    puts
    puts "To complete the installation, execute the following:".lightblue
    puts "echo '# Sommelier environment variables + daemon' >> ~/.bashrc".lightblue
    puts "echo '# See https://github.com/dnschneid/crouton/wiki/Sommelier-(A-more-native-alternative-to-xiwi)' >> ~/.bashrc".lightblue
    puts "echo 'if [ ! -d /tmp/.X11-unix ]; then' >> ~/.bashrc".lightblue
    puts "echo 'mkdir /tmp/.X11-unix' >> ~/.bashrc".lightblue
    puts "echo 'fi' >> ~/.bashrc".lightblue
    puts "echo 'sudo chmod -R 1777 /tmp/.X11-unix' >> ~/.bashrc".lightblue
    puts "echo 'sudo chown root:root /tmp/.X11-unix' >> ~/.bashrc".lightblue
    puts "echo 'alias startsommelier=\"source ~/.sommelier.env && initsommelier\"' >> ~/.bashrc".lightblue
    puts "echo 'startsommelier' >> ~/.bashrc".lightblue
    puts "source ~/.bashrc".lightblue
    puts
    puts "To start the sommelier daemon, run 'startsommelier'".lightblue
    puts "To stop the sommelier daemon, run 'stopsommelier'".lightblue
    puts
    puts "To adjust environment variables, edit ~/.sommelier.env".lightblue
    puts
    puts "You may need to adjust the SCALE environment variable to get the correct screen size.".lightblue
    puts
    puts "Please be aware that gui applications may not work without the sommelier daemon running.".orange
    puts
    puts "If you are upgrading from an earlier version of sommelier, edit ~/.bashrc".orange
    puts "and remove the former 'Sommelier environment variables + daemon' section.".orange
    puts
  end
end
