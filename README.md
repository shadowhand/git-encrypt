# Transparent Git Encryption

The gitcrypt tool is inspired by [this document][1] written by [Ning Shang][2],
which was in turn inspired by [this post][3]. Without these two documents,
by people much smarter than me, gitcrypt would not exist.

> There is [some controversy][4] over using this technique, so do your research
and understand the implications of using this tool before you go crazy with it.

## Features

**Not Verified on Windows**

Now you can encrypt/decrypt and recrypt(change passphrase) all history

	$ gitcrypt crypthistory
	$ gitcrypt decrypthistory
	$ gitcrypt recrypt


## Requirements
Openssl must be installed and the binary must be available in your $PATH.

## Installation

### From a package manager
Install from npm:

    npm install -g git-encrypt

Install from Homebrew:

    brew install git-encrypt

### Manually

Clone git-encrypt somewhere on your local machine:

    $ git clone https://github.com/shadowhand/git-encrypt
    $ cd git-encrypt

The `gitcrypt` command must be executable:

    $ chmod 0755 gitcrypt

And it must be accessible in your `$PATH`:

    $ sudo ln -s "$(pwd)/gitcrypt" /usr/local/bin/gitcrypt

### For Windows

**Verified on PortableGit Only !**

Copy the file gitcrypt to your PortableGit/bin location. In my environment PortableGit is
available at E:\PortableGit. 

> copy gitcrypt E:\PortableGit\bin

Also make sure that PATH environment variable has E:\PortableGit\bin 
available in it.

> Path=C:\Python27\;C:\Python27\Scripts;E:\PortableGit\bin;E:\PortableGit\libexec\git-core;C:\windows\system32;C:\windows\;C:\window
> s\system32\WBEM;c:\windows\System32\WindowsPowerShell\v1.0\;c:\i386\~configs;C:\Users\VKHANORK\AppData\Roaming\Python\Scripts

Setup gitcrypt:

> E:\>mkdir TEST
> 
> E:\>cd TEST
> 
> E:\TEST>git init
> Initialized empty Git repository in E:/TEST/.git/
> 
> E:\TEST>git config core.autocrlf false
> 
> E:\TEST>E:\PortableGit\bin\bash.exe E:\PortableGit\bin\gitcrypt init
> Generate a random salt? [Y/n]
> Generate a random password? [Y/n]
> What encryption cipher do you want to use? [aes-256-ecb]
> 
> This configuration will be stored:
> 
> salt:   5ecc05565042de81
> pass:   iLC#GkuzE1iOmUVItIQww8**oBDTfKE2
> cipher: aes-256-ecb
> 
> Does this look right? [Y/n]
> Do you want to use .git/info/attributes? [Y/n]
> What files do you want encrypted? [*]
> 
> E:\TEST>

## Configuration

To quickly setup gitcrypt interactively, run `gitcrypt init` from the root
of your git repository. It will ask you for a passphrase, shared salt,
cipher mode, and what files should be encrypted.

    $ cd my-repo
    $ gitcrypt init

Your repository is now set up! Any time you `git add` a file that matches the
filter pattern the `clean` filter is applied, automatically encrypting the file
before it is staged. Using `git diff` will work normally, as it automatically
decrypts file content as necessary.

### Manual Configuration

First, you will need to add a shared salt (16 hex characters) and a secure
passphrase to your git configuration:

    $ git config gitcrypt.salt 0000000000000000
    $ git config gitcrypt.pass my-secret-phrase

> It is possible to set these options globally using `git config --global`,
but more secure to create a separate passphrase for every repository.

The default [encryption cipher][5] is `aes-256-ecb`, which should be suitable
for almost everyone. However, it is also possible to use a different cipher:

    $ git config gitcrypt.cipher aes-256-ecb

> An "ECB" mode is used because it encrypts in a format that provides usable
text diff, meaning that a single change will not cause the entire file to be
internally marked as changed. Because a static salt must be used, using "CBC"
would provide very little, if any, increased security over "ECB" mode.

Next, you need to define what files will be automatically encrypted using the
[.git/info/attributes][6] file. Any file [pattern format][7] can be used here.

To encrypt all the files in the repo:

    * filter=encrypt diff=encrypt
    [merge]
        renormalize = true

To encrypt only one file, you could do this:

    secret.txt filter=encrypt diff=encrypt

Or to encrypt all ".secure" files:

    *.secure filter=encrypt diff=encrypt

> If you want this mapping to be included in your repository, use a
`.gitattributes` file instead and **do not** encrypt it.

Next, you need to map the `encrypt` filter to `gitcrypt`:

    $ git config filter.encrypt.smudge "gitcrypt smudge"
    $ git config filter.encrypt.clean "gitcrypt clean"
    $ git config diff.encrypt.textconv "gitcrypt diff"

Or if you prefer to manually edit `.git/config`:

    [filter "encrypt"]
        smudge = gitcrypt smudge
        clean = gitcrypt clean
    [diff "encrypt"]
        textconv = gitcrypt diff

## Decrypting Clones

To set up decryption from a clone, you will need to repeat the same setup on
the new clone.

First, clone the repository, but **do not perform a checkout**:

    $ git clone -n git://github.com/johndoe/encrypted.git
    $ cd encrypted

> If you do a `git status` now, it will show all your files as being deleted.
Do not fear, this is actually what we want right now, because we need to setup
gitcrypt before doing a checkout.

Now you can either run `gitcrypt init` or do the same manual configuration that
performed on the original repository.

Once configuration is complete, reset and checkout all the files:

    $ git reset --hard HEAD

All the files in the are now decrypted and ready to be edited.

# Alternate method: git-encrypt-init.sh

Contributed by [Jay Taylor](https://jaytaylor.com "jaytaylor.com")


The git-encrypt-init.sh shell script automatically performs all prepartion,
setup and configuration for a local repository clone, prompting the user for
any required information (salt and password phrases.)  This method of also
ensures that the git-encrypt scripts are automatically installed to
`~/.gitencrypt/`. One drawback to this approach is that it only supports having
1 password.

One reason to use this alternate approach is because it makes decrypting cloned
repositories as simple as executing one script.

## Usage

Once you've cloned git-encrypt using the alternate script is straightforward:

    $ cd /path/to/your/repository
    $ sh /path/to/git-encrypt/git-encrypt-init.sh

Then you can add the files you would like to have encrypted to the
.gitattributes file contained in the root of your repository.


# Conclusion

Enjoy your secure git repository! If you think gitcrypt is totally awesome,
you could [buy me something][wishes] or [donate some money][donate].

[1]: http://syncom.appspot.com/papers/git_encryption.txt "GIT transparent encryption"
[2]: http://syncom.appspot.com/
[3]: http://git.661346.n2.nabble.com/Transparently-encrypt-repository-contents-with-GPG-td2470145.html "Web discussion: Transparently encrypt repository contents with GPG"
[4]: http://article.gmane.org/gmane.comp.version-control.git/113221 "Junio Hamano does not recommend this technique"
[5]: http://en.wikipedia.org/wiki/Cipher
[6]: http://www.kernel.org/pub/software/scm/git/docs/gitattributes.html
[7]: http://www.kernel.org/pub/software/scm/git/docs/gitignore.html#_pattern_format

[wishes]: http://www.amazon.com/gp/registry/wishlist/1474H3P2204L8
[donate]: http://www.pledgie.com/campaigns/14931
