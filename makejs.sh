jsdoc -r data/.
sleep 1.5

cd ..
if [ ! -d data/out ]; then
mkdir data/out
fi
cp -R out/. data/out