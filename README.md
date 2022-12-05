# Parametrically Generated 3D Printable ABLOY Keys

The repo I forked this from does not properly support Abloy Disklock (not Disklock Pro) keys.
I've adjusted several measurements in the code to make working keys.

## Usage

The easiest way to use this is to create a new `.scad` file that uses the desired library.

### Disklock ®

<img src="http://lockwiki.com/images/4/4e/Abloy_Disklock_key_bitting.jpg" width="300">

```scad
use <disklock.scad>

// note: zero bitting standard in tension discs (0 and 7)
disklock([0,6,1,4,2,3,1,0,5,2],tip_cuts=[0],label="Sample");
```

The `tip_cuts` list indicates which sections of the tips should have warding cut out and ranges from 0 to 6.
Alternative the `tip_cut_all` flag can be set to true to generate a modified tip that should work in most if not all
locks.

## References

* [Lockwiki](http://lockwiki.com) LockWiki
  * [Disklock](http://lockwiki.com/index.php/Abloy_Disklock)
* [Toool](https://toool.nl/) Evolution of Abloy series
  * [Abloy Disklock](https://toool.nl/images/f/f3/Abloypart2.pdf)
