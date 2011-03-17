# Transparent Git Encryption

The gitcrypt tool is inspired by [this document][1] written by [Ning Shang][2],
which was in turn inspired by [this post][1]. Without these two documents,
by people much smarter than me, gitcrypt would not exist.

## Installation

Clone git-encrypt somewhere on your local machine:

    $ git clone https://github.com/shadowhand/git-encrypt
    $ cd git-encrypt

The `gitcrypt` command must be executable:

    $ chmod 0755 gitcrypt

And it must be accessible in your `$PATH`:

    $ sudo ln -s gitcrypt /usr/bin/gitcrypt

## Configuration

First, you will need to add a secret salt and secure passphrase to your git
configuration. The secret salt must be 16 **hexidecimal** chacaters and the
secure passphrase can be any characters of any length:

    $ git config gitcrypt.salt 0000000000000000
    $ git config gitcrypt.pass my-secret-phrase

*It is possible to set these options globally using `git config --global`, but
more secure to create a separate salt and passphrase for every repository.*

A quick way to generate a new salt is:

    $ head -c 10 < /dev/random | md5 | cut -c-16

## Usage

For every repository that you want to use gitcrypt in, you will need a
[.gitattributes][4] file to define what files will be encrypted. Any file
[pattern format][5] can be used here.

To encrypt all the files in the repo:

    * filter=encrypt diff=encrypt
    [merge]
        renormalize = true

To encrypt only one file, you could do this:

    secret.txt filter=encrypt diff=encrypt

Or to encrypt all ".secure" files:

    *.secure filter=encrypt diff=encrypt

*Note: It is not recommended to add your `.gitattributes` file to the
repository itself. Instead, add `.gitattributes` to your `.gitignore` file
or use `.git/info/attributes` instead.*

Next, you need to map the `encrypt` filter to `gitcrypt` using `git config`:

    $ git config filter.encrypt.smudge "gitcrypt smudge"
    $ git config filter.encrypt.clean "gitcrypt clean"
    $ git config diff.encrypt.textconv "gitcrypt diff"

Or if you prefer to manually edit `.git/config`:

    [filter "encrypt"]
        smudge = gitcrypt smudge
        clean = gitcrypt clean
    [diff "encrypt"]
        textconv = gitcrypt diff

Your repository is now set up! Any time you `git add` a file that matches the
filter pattern the `clean` filter is applied, automatically encrypting the file
before it is staged. Using `git diff` will work normally, as it automatically
decrypts file content as necessary.

### Decryption and Clones

To set up decryption from a clone, you will need to repeat most of these steps
on the other side.

First, clone the repository, but **do not perform a checkout**:

    $ git clone -n git://github.com/johndoe/encrypted.get
    $ cd encrypted

If you do a `git status` now, it will show all your files as being deleted.
Do not fear, this is actually what we want right now, because we need to setup
gitcrypt before doing a checkout. Now we just repeat the configuration as it
was done for the original repo.

Second, set your encryption salt and passphrase:

    $ git config gitcrypt.salt 0123456789abcdef
    $ git config gitcrypt.pass "gosh, i am so insecure!"

Third, edit `.gitattributes` or `.git/info/attributes`:

    * filter=encrypt diff=encrypt
    [merge]
        renormalize = true

Fourth, map the `encrypt` filter:

    $ git config filter.encrypt.smudge "gitcrypt smudge"
    $ git config filter.encrypt.clean "gitcrypt clean"
    $ git config diff.encrypt.textconv "gitcrypt diff"

Configuration is complete, now reset and checkout all the files:

    $ git reset HEAD
    $ git ls-files --deleted | xargs git checkout --

All the files in the are now decrypted and ready to be edited.

# Conclusion

Enjoy your secure git repository! If you think gitcrypt is totally awesome,
you could [buy me a beer][wishes].

[1]: http://syncom.appspot.com/papers/git_encryption.txt "GIT transparent encryption"
[2]: http://syncom.appspot.com/
[3]: http://git.661346.n2.nabble.com/Transparently-encrypt-repository-contents-with-GPG-td2470145.html "Web discussion: Transparently encrypt repository contents with GPG"
[4]: http://www.kernel.org/pub/software/scm/git/docs/gitattributes.html
[5]: http://www.kernel.org/pub/software/scm/git/docs/gitignore.html#_pattern_format

[wishes]: http://www.amazon.com/gp/registry/wishlist/1474H3P2204L8 "Woody Gilk's Wish List on Amazon.com"
