# Absynth
Parameterized layout synthesis module

## Build  on Arch Linux : 
### Setup Environment:
```
yay -Syy fpc-src lazarus-qt5
git clone https://github.com/cloudcalvin/Absynth.git
```

### Compile 
```
cd Absynth
lazbuild Absynth.lpi
```

### Test 
```
cd Examples/
../lib/Absynth -a jj250.abs
``` 
