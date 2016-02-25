This directory holds the Android implementation of the Glibc module, Bionic.
Like the Linux Glibc module, it is comprised of:
- The *overlay* library, which amends some APIs imported from Glibc, and
- The clang [module map](http://clang.llvm.org/docs/Modules.html) which
  specifies which headers need to be imported from Glibc for bare minimum
  functionality.
