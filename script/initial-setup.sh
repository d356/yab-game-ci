#install dependencies
dnf install -y ruby cmake gcc gcc-c++
gem install bundler

#get binary files
git clone https://github.com/d356/yabauseut-bin.git

#setup web app
cd web
bundle install
