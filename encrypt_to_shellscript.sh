#!/bin/bash
if [ $# -eq 0 ]; then
    >&2 echo "Usage: cat file.tgz | encrypt_to_shellscript.sh (password) > file.tgz.ssl.sh"
    exit 1
fi
echo 'if [ "$1" == "--extract" ]; then'
echo '  >&2 echo "This script decrypts and extracts the contained file."'
echo 'else'
echo '  >&2 echo "This script decrypts the contained file to stdout.  Use --extract to extract file to current directory."'
echo 'fi'
echo "linenum=\$(grep -n \"__END_OF_SCRIPT_MARKER__\" \"\$0\" | tail -1 | sed -e 's/:.*//')"
echo "if [ \"\$1\" == \"--extract\" ]; then"
echo "  tail -n +\$((\$linenum + 1)) \"\$0\" | openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -a -d | tar -xvz"
echo "else"
echo "  tail -n +\$((\$linenum + 1)) \"\$0\" | openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -a -d"
echo "fi"
echo 'exit 0'
echo '__END_OF_SCRIPT_MARKER__'
cat - | openssl enc -aes-256-cbc -md sha512 -salt -pbkdf2 -iter 100000 -a -pass pass:$1
