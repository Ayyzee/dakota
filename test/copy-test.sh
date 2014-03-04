#!/sh -u

if [ 2 != $# ]; then
  echo "usage: $0 <0|1|2|3> <test-name>"
fi

cp -r TEMPLATE-exe-$1 $2
rm -rf $2/.svn
