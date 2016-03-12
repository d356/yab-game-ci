#compile runner
cd ..
rm -rf yabause
git clone https://github.com/Yabause/yabause.git
cd yabause/yabause/src/runner
git clone git://github.com/lvandeve/lodepng.git
cd ../../../
mkdir build
cd build
cmake -DYAB_PORTS=runner -DYAB_WANT_OPENGL=OFF ../yabause/
make

#run game testing
mkdir failures
git clone https://github.com/d356/yabauseut-bin.git
./src/runner/yabause game check ../../game_data.txt ../../paths.txt ./yabauseut-bin/game_screenshots/ ./failures/
