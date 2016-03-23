#compile runner
cd ..
cd yabause/yabause/src/runner
git clone git://github.com/lvandeve/lodepng.git
cd ../../../
mkdir build
cd build
cmake -DYAB_PORTS=runner -DYAB_WANT_OPENGL=OFF ../yabause/
make

#run game testing
rm -rf failures
mkdir failures
./src/runner/yabause game check ../../game_data.txt ../../paths.txt ../../images/ ./failures/
cp -r ./failures/. ../../web/public/
