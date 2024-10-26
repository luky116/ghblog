
rm -rf ./public/*

hugo -d ./public

cd public
git init
git remote add origin git@github.com:luky116/luky116.github.io.git
git add -A
git commit -m "update new blog"
git push -f origin master
