## phpbs
### PHP Building system for all PHP versions packages from 5.3 to 8.1

#### How to install it? 
```
git clone https://github.com/lamskoy/arch-phpbs.git
cd arch-phpbs
```

Now you're the boss and ready to go with building packages


#### How to use it?

To build all packages:
```
make all
```

To build specific version:
```
make php81
```

Available targets are : php81 php80 php74 php73 php72 php71 php70 php56 php55 php54 php53

To build all php8.x (8.0 and 8.1):
```
make php8
```

You can mix targets in any combination

This will build: 5.6, 8.1, 8.0, 7.4:
```
make php56 php8 php74
```

Use ``make help`` to see more details

### Who can use it?

Anybody who uses ArchLinux or it's derivatives like Manjaro
