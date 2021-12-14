#
declare -rig _phpbase=%PHPBASE%
declare -rg _suffix=%SUFFIX%
#
pkgbase="php${_phpbase}${_suffix}"
pkgname=("${pkgbase}")
pkgdesc="php ${pkgver} compiled as to not conflict with mainline php"
arch=('i686' 'x86_64')
license=('PHP')
url='http://www.php.net'
checkdepends=('procps-ng')

# pkgrel
pkgrel=1

# Vars
source=()
_submodules=()
_patches=()
makedepends=()

# Pkgver
case "${_phpbase}" in
    81) pkgver=8.1.0  ;;
    80) pkgver=8.0.13 ;;
    74) pkgver=7.4.26 ;;
    73) pkgver=7.3.33 ;;
    72) pkgver=7.2.34 ;;
    71) pkgver=7.1.33 ;;
    70) pkgver=7.0.33 ;;
    56) pkgver=5.6.40 ;;
    55) pkgver=5.5.38 ;;
    54) pkgver=5.4.45 ;;
    53) pkgver=5.3.29 ;;
esac

# Consts
declare -rg _fpm_user=http
declare -rg _fpm_group=http
declare -rg _php5_icu=usr/lib/php5-libs/icu-64-1
declare -rg _php5_gd=usr/lib/php5-libs/gd-2.1.1

# PHP major version, constant
declare -rg _php_major_minor=$(echo "$pkgver" | grep -Eo '([0-9]+\.[0-9]+)')

# Binary/conf names
if ((_phpbase >= 80)); then
    # No libapache8.so, in PHP8.0+ just libapache etc
    declare -rg _so_suffix=''
else
    declare -rg _so_suffix="${_phpbase::1}";    
fi
declare -rg name_phpconfig="php-config${_phpbase}${_suffix}"
declare -rg name_phpize="phpize${_phpbase}${_suffix}"
declare -rg name_phar="phar${_phpbase}${_suffix}"
declare -rg name_libembed_source="libphp${_so_suffix}.so"
declare -rg apache_cfg="etc/httpd/conf/extra"
declare -rg name_apache_module_conf="${pkgbase}-module.conf"
declare -rg name_libapache_source="libphp${_so_suffix}.so"
declare -rg name_mod_php="php_module${_so_suffix}"
declare -rg name_script_php="php${_so_suffix}-script"
declare -rg name_php_fpm="php${_phpbase}${_suffix}-fpm"
# End Binary/conf names

# SAPI config
# 5.3 can't be built as newer versions, look build()
declare -rig _build_per_sapi=$((_phpbase == 53))
declare -rig _build_pear=1
# Segfaulting in 5.6 for me :(
declare -rig _build_phpdbg=$((_phpbase > 56))
declare -rig _build_json=$((_phpbase < 80))
# End sapi config

# Modules config
# FFI appears first in 7.4, enable it
declare -rig _build_ffi=$((_phpbase >= 74));
# These modules are not available since 7.4
declare -rig _build_recode=$((_phpbase < 74));
declare -rig _build_wddx=$((_phpbase < 74));
declare -rig _build_interbase=$((_phpbase < 74));
declare -rig _build_xmlrpc=$((_phpbase < 74));
# Always
declare -rig _build_shared_gd=1
# Bug with external gd with PHP5 <= 5.4
declare -rig _build_bundled_gd=$((_phpbase <= 54 && _phpbase >= 50))
# PHP 5.3 fails to build shared PDO with shared sqlite
declare -rig _build_static_pdo=$((_phpbase <= 53 && _phpbase >= 50))
# Since 5.5 we have opcache
declare -rig _build_opcache=$((_phpbase >= 55));
declare -rig _build_sodium=$((_phpbase >= 72));
# invert sodium flag
declare -rig _build_mcrypt=$((_build_sodium ^ 1));
# Db stuff
declare -rig _build_outdated_mysql=$((_phpbase >= 50 && _phpbase <= 59))
declare -rig _build_mssql=$((_phpbase >= 50 && _phpbase <= 59))
# End modules config 

# Not all patches are ready now
declare -rig _build_openssl_v11_patch=$((_phpbase >= 56 && _phpbase <= 59))
declare -rig _build_openssl_v10_patch=$((_phpbase < 70 && _phpbase >= 53 && ! _build_openssl_v11_patch))
declare -rig _build_uses_autoconf=$((! _build_openssl_v10_patch));

if ((_build_openssl_v11_patch)); then    
    _patches+=("openssl-1.1.patch")
elif ((_build_openssl_v10_patch)); then
    _patches+=("openssl-1.0.patch")
fi
if ((_build_openssl_v10_patch && _phpbase <= 54)); then
    _patches+=("openssl-sslv3.patch") 
fi 

if ((_phpbase >= 54 && _phpbase <= 59)); then
    # PHP >= 5.4 && PHP < 7: Upgrade sqlite lib to 3.28
    _patches+=("sqlite-3.28-php5.4.patch")
fi

if ((56 == _phpbase)); then
    # Defensive mode for sqlite 
    _patches+=("sqlite-defensive-php5.6.patch")
elif ((70 == _phpbase)); then
    # Defensive mode for sqlite 
    _patches+=("sqlite-defensive-php7.0.patch")
    # PHP == 7.0: Upgrade sqlite lib to 3.28
    _patches+=("sqlite-3.28-php7.0.patch")    
elif ((53 == _phpbase)); then
    _patches+=("cve-php5.3.patch")
    _patches+=("mpm-apache.patch")
fi

if ((_phpbase >= 53 && _phpbase <= 73)); then
    # Useful patches: possibility ti use GID/UID
    # instead of username/group for fpm
    # and reload on sighup
    _patches+=("fpm-numeric-uid-gid.patch")
    _patches+=("fpm-reload-sighup.patch")
fi

if ((_phpbase >= 50 && _phpbase <= 70)); then
    _patches+=("mysql-socket-php5.3.patch")
elif ((_phpbase >= 71 && _phpbase <= 79)); then
    _patches+=("mysql-socket-php7.1.patch")
fi

if ((_phpbase >= 53 && _phpbase <= 73)); then
    # Enchant 2 support patches for PHP >= 5.3 and PHP < 7.4
    _patches+=("php-enchant-php5.3.patch")
    _patches+=("php-enchant-depr.patch");
elif ((74 == _phpbase)); then
    # Enchant 2 support patch for PHP == 7.4
    _patches+=("enchant-php7.4.patch")
fi

if ((_phpbase >= 54 && _phpbase <= 73)); then
    _patches+=("php-freetype-2.9.1.patch")
fi

if ((_phpbase >= 55 && _phpbase <= 72)); then
    _patches+=("php-icu-php5.5.patch")
elif ((73 == _phpbase)); then
    _patches+=("php-icu-php7.3.patch")
fi

if ((_phpbase >= 54 && _phpbase <= 73)); then
    _patches+=("recode-php5.4.patch")
elif ((_phpbase == 53)); then
    _patches+=("recode-php5.3.patch")
fi     
if ((_phpbase >= 55 && _phpbase <= 59)); then
    _patches+=("php-opcache-lockfile-path.patch")
fi    

if ((_phpbase >= 53 && _phpbase <= 59)); then
    _patches+=("php-mysqlnd-charsets.patch")
    _patches+=("php-mysqlnd.patch")
fi

if ((_phpbase >= 53 && _phpbase <= 54)); then
    _patches+=("php-tests.patch")    
fi

if ((_build_uses_autoconf)); then
    # This is useful debian patch for autodetection of timezone
    # AND linking with system tzdata instead of bundled
    _use_system_timezonedb=1
    _patches+=("timezonedb-guess.patch")
    _patches+=("timezonedb-php${_php_major_minor}.patch")    
fi

if ((_phpbase >= 53 && _phpbase <= 81)); then
    # Include CVEs and other useful patches from debian
    _patches+=("debian-php-${pkgver}.patch")
fi
# End patches
    
# Common makedepends
makedepends+=(
    'apache' 'aspell' 'c-client' 'db' 'enchant' 'gmp' 'icu' 'libxslt' 'libzip' 'net-snmp'
    'postgresql-libs' 'sqlite' 'systemd' 'unixodbc' 'curl' 'libtool' 'freetds' 'pcre' 
    'tidy' 'libfbclient' 'patchutils' 'oniguruma' 'patchelf' 'gd' 'argon2' 'autoconf'
    'automake'
)

# Basic submodules, order is important!
_submodules+=('cli' 'cgi' 'apache' 'fpm' 'embed')

# Sub packages provided by extensions
_submodules+=(
    'enchant' 'imap' 'intl' 'odbc' 'pgsql' 'pspell' 'snmp' 'tidy' 'curl' 'ldap' 'bz2'
    'bcmath' 'soap' 'zip' 'gmp' 'dba' 'interbase' 'xml' 'mysql' 'sqlite' 'dblib' 'gd'
)

# Sources
source+=(
    "pear-config-patcher.php"
    "php-apache.conf"     
)

if ((_phpbase >= 53 && _phpbase <= 54)); then
    source+=("https://php.net/distributions/php-${pkgver}.tar.bz2")
    makedepends+=("php5-libs")
else
    source+=("https://php.net/distributions/php-${pkgver}.tar.xz")
fi

# Append patches to source :)
source+=("${_patches[@]}")

# Process BUILD stuff
if ((_build_mcrypt)); then    
    makedepends+=('libmcrypt')
    _submodules+=('mcrypt')
fi
if ((_build_phpdbg)); then
    _submodules+=('phpdbg')
fi
if ((_build_pear)); then
    _submodules+=('pear')
fi
if ((_build_xmlrpc)); then
    _submodules+=('xmlrpc')
fi
if ((_build_opcache)); then
    _submodules+=('opcache')
fi
if ((_build_sodium)); then
    makedepends+=("libsodium")
    _submodules+=('sodium')
fi
if ((_build_recode)); then
    makedepends+=('recode')
    _submodules+=('recode')
fi
if ((_build_json)); then
    _submodules+=('json')
fi
if ((_build_openssl_v10_patch)); then
    makedepends+=('openssl-1.0')
fi

# Declare submodules
for i in "${_submodules[@]}"; do 
    pkgname+=("php${_phpbase}-${i}${_suffix}");
done


# Priority
declare -rig _priority_default=20
declare -rig _priority_mysqlnd=10
declare -rig _priority_pdo=10
declare -rig _priority_opcache=10
declare -rig _priority_xml=15
declare -rig _priority_json=15

# Temp vars
_last_priority=
_last_extension=

# Prepare our stuff with patches :)
prepare() {
    pushd "php-${pkgver}"
    echo "[SED] sapi/apache2handler/config.m4 and configure"
    sed -e '/APACHE_THREADED_MPM=/d' \
        -i sapi/apache2handler/config.m4 \
        -i configure

    
    echo "[SED] sapi/fpm/Makefile.frag"
    sed -e 's#php-fpm\$(program_suffix)#php\$(program_suffix)-fpm#' \
        -e 's/.conf.default/.conf/g' \
        -i sapi/fpm/Makefile.frag       

    echo "[SED] sapi/fpm/php-fpm.service.in"
    sed -E "s|ExecStart[\s]?=[\s]?@([a-zA-Z_]+)@/php-fpm|ExecStart=@\1@/${name_php_fpm}|g; \
            s|PIDFile[\s]?=[\s]?@([a-zA-Z_]+)@/run/php-fpm.pid|PIDFile=/run/${name_php_fpm}/php-fpm.pid|g" \
        -i sapi/fpm/php-fpm.service.in           

    local _check_files=("sapi/fpm/www.conf.in" "sapi/fpm/php-fpm.conf.in");
    for file_conf in "${_check_files[@]}"; do
        if [[ ! -f $file_conf  ]]; then
            continue;
        fi
        echo "[SED] ${file_conf}"
        sed -e "s#^listen =.*#listen = /run/${name_php_fpm}/php-fpm.sock#" \
            -e "s#run/php-fpm.pid#/run/${name_php_fpm}/php-fpm.pid#" \
            -e 's#^;*[ \t]*listen.owner =#listen.owner =#' \
            -e 's#^;*[ \t]*listen.group =#listen.group =#' \
            -e 's#^;*[ \t]*error_log =.*#error_log = syslog#' \
            -e 's#^;*[ \t]*chdir =.*#;chdir = /srv/http#' \
            -i "${file_conf}"          
    done

    echo "[SED] php.ini-production"
    sed -e 's#^;*[ \t]*extension_dir[\t ]*=.*/.*$#extension_dir = "%EXTENSIONDIR%"#' \
        -e "s#%EXTENSIONDIR%#/usr/lib/php${_phpbase}${_suffix}/modules#g" \
        -e "s#^;*[ \t]*extension=#;extension=#g" \
        -i php.ini-production
    
    for patch_name in "${_patches[@]}"; do
        echo "[PATCH] Applying source patch ${patch_name}";
        patch -p1 -i "../${patch_name}"
    done
    
    if ((_build_uses_autoconf)); then
        autoconf
    fi  
    
    if ((_phpbase >= 72)); then
        rm -f tests/output/stream_isatty_*.phpt
    fi
    if ((_phpbase >= 80)); then
        rm -f Zend/tests/arginfo_zpp_mismatch*.phpt    
    fi            
    popd
}


# BUILD them all 

build() {  
    export EXTENSION_DIR="/usr/lib/php${_phpbase}${_suffix}/modules"
    if ((_build_openssl_v10_patch)); then
        export PHP_OPENSSL_DIR="/usr/lib/openssl-1.0"
    fi

    local _new_flags=' -DU_USING_ICU_NAMESPACE=1 '
    if ((_phpbase >= 53 && _phpbase <= 55)); then
        # Openssl 1.0.x in Arch doesn't have SSLv3 support compiled
        _new_flags+=' -DOPENSSL_NO_SSL3=1 '
        _new_flags+=' -DOPENSSL_NO_SSL2=1 '
    fi
    if ((_phpbase < 80)); then
        # PHP 5 and 7 need this stuff
        _new_flags+=' -DU_DEFINE_FALSE_AND_TRUE=1 '
    fi
    
    local _phpconfig="\
        --srcdir=../php-${pkgver} \
        --prefix=/usr \
        --sbindir=/usr/bin \
        --sysconfdir=/etc/php${_phpbase}${_suffix} \
        --localstatedir=/var \
        --libdir=/usr/lib/php${_phpbase}${_suffix} \
        --datadir=/usr/share/php${_phpbase}${_suffix} \
        --program-suffix=${_phpbase}${_suffix} \
        --with-layout=GNU \
        --with-config-file-path=/etc/php${_phpbase}${_suffix} \
        --with-config-file-scan-dir=/etc/php${_phpbase}${_suffix}/conf.d \
        --disable-debug \
        --mandir=/usr/share/man \
        --without-pear \
        "
    if ((_phpbase > 53)); then
        _phpconfig+=" --config-cache "
        _phpconfig+=" --datarootdir=/usr/share/php${_phpbase}${_suffix} "
    fi    
    if ((_use_system_timezonedb)); then
        _phpconfig+=" --with-system-tzdata "
    fi
    
    local _phpextensions="\
        --enable-bcmath=shared \
        --with-bz2=shared,/usr \
        --with-gmp=shared,/usr \
        --enable-intl=shared \
        --with-pspell=shared,/usr \
        --with-snmp=shared,/usr \
        --with-tidy=shared,/usr \
        --enable-filter \
        --with-readline \  
        --enable-pcntl \
        "
    if ((_build_json)); then
        _phpextensions+=" --enable-json=shared " 
    fi
    if ((_phpbase >= 80)); then
        _phpextensions+=" --with-password-argon2 "
    fi
    if ((_build_recode)); then
        _phpextensions+=" --with-recode=shared "
    fi
    if ((_build_ffi)); then
        _phpextensions+=" --with-ffi=shared "
    fi
    if ((_phpbase >= 74)); then
        _phpextensions+=" --with-zip=shared "
        _phpextensions+=" --with-curl=shared "
        _phpextensions+=" --with-enchant=shared "
        _phpextensions+=" --with-pcre-jit "
        _phpextensions+=" --with-external-pcre=/usr "
        _phpextensions+=" --with-openssl "
        # odbc pdo_odbc
        _phpextensions+="\
            --with-unixODBC=shared \
            --with-pdo-odbc=shared,unixODBC,/usr \
            "
        _phpextensions+="\
            --with-ldap=shared,/usr \
            --with-ldap-sasl \
            "            
        # sqlite3 pdo_sqlite
        _phpextensions+="\
            --with-pdo-sqlite=shared,/usr \
            --with-sqlite3=shared \
            "                  
    else
        _phpextensions+=" --enable-zip=shared "
        _phpextensions+=" --with-curl=shared,/usr  "
        _phpextensions+=" --with-enchant=shared,/usr "        
        _phpextensions+=" --with-pcre-regex=/usr "
        _phpextensions+=" --with-openssl=/usr "
        # odbc pdo_odbc
        _phpextensions+="\
            --with-unixODBC=shared,/usr \
            --with-pdo-odbc=shared,unixODBC,/usr \
            "        
        _phpextensions+="\
            --with-ldap=shared,/usr \
            --with-ldap-sasl=/usr \
            "
        # sqlite3 pdo_sqlite
        _phpextensions+="\
            --with-pdo-sqlite=shared,/usr \
            --with-sqlite3=shared,/usr \
            "            
        _phpextensions+="\
            --enable-hash \
            --with-mhash=/usr \
            "
    fi


    local _with_gd_word="--with-gd"
    if ((_phpbase >= 74)); then
        _with_gd_word="--enable-gd"
    fi
       
    if (( ! _build_shared_gd && _build_bundled_gd )); then
            _phpextensions+=" ${_with_gd_word} "
    elif (( _build_shared_gd && _build_bundled_gd )); then
            _phpextensions+=" ${_with_gd_word}=shared "
    elif (( _build_shared_gd && ! _build_bundled_gd )); then
        if ((_phpbase >= 74)); then
            _phpextensions+=" ${_with_gd_word}=shared --with-external-gd=/usr "
        else
            _phpextensions+=" ${_with_gd_word}=shared,/usr "
        fi
    else
        if ((_phpbase >= 74)); then
            _phpextensions+=" --${_with_gd_word} -with-external-gd=/usr "  
        else
            _phpextensions+=" ${_with_gd_word}=/usr "     
        fi    
    fi 
 
    if ((_phpbase < 72)); then
        _phpextensions+=" --enable-gd-native-ttf "
    fi
    if ((_phpbase >= 55 && _phpbase < 72)); then
        _phpextensions+=" --with-vpx-dir=/usr "
    fi
    if ((_phpbase >= 74)); then
        _phpextensions+="\
            --with-jpeg \
            --with-xpm \
            --with-webp \
            --with-freetype \
            "
    else
        # PHP 5.3 and 5.4 says --with-webp-dir is not recognized, but it does recognize it
        # gd.so can't work normally if no webp is defined!
        # --with-gd=shared also should be enabled for them to build fine
        _phpextensions+="\
            --with-webp-dir=/usr \
            --with-jpeg-dir=/usr \
            --with-png-dir=/usr \
            --with-xpm-dir=/usr \
            --with-freetype-dir=/usr \
            "
    fi


    if ((_phpbase > 55 && _phpbase < 74)); then
        _phpextensions+=" --with-libzip=/usr "
    fi


    # calendar ctype exif fileinfo ftp gettext iconv pdo phar posix shmop sockets sysvmsg sysvsem sysvshm tokenizer
    _phpextensions+="\
        --enable-calendar=shared \
        --enable-ctype=shared \
        --enable-exif=shared \
        --enable-fileinfo=shared \
        --enable-ftp=shared \
        --with-gettext=shared,/usr \
        --with-iconv=shared \
        --enable-phar=shared \
        --enable-posix=shared \
        --enable-shmop=shared \
        --enable-sockets=shared \
        --enable-sysvmsg=shared \
        --enable-sysvsem=shared \
        --enable-sysvshm=shared \
        --enable-tokenizer=shared \
        "

    if ((_build_static_pdo)); then
        _phpextensions+=" --enable-pdo "
    else
        _phpextensions+=" --enable-pdo=shared "        
    fi

    # mysqlnd mysqli pdo_mysql
    _phpextensions+="\
        --enable-mysqlnd=shared \
        --enable-mysqlnd-compression-support \
        --with-mysqli=shared,mysqlnd \
        --with-pdo-mysql=shared,mysqlnd \
        --with-mysql-sock=/run/mysqld/mysqld.sock \
        "
    if ((_phpbase < 70)); then
        _phpextensions+=" --with-zlib-dir=/usr "
    else
        _phpextensions+=" --with-zlib"
    fi       

    if ((_build_outdated_mysql)); then
        _phpextensions+=" --with-mysql=shared,mysqlnd "
    fi

    # dom simplexml wddx xml xmlreader xmlwriter xsl
    _phpextensions+="\
        --enable-dom=shared \
        --enable-simplexml=shared \
        --enable-xml=shared \
        --enable-xmlreader=shared \
        --enable-xmlwriter=shared \
        --with-xsl=shared \
        "

    if ((_build_wddx)); then
        _phpextensions+=" --enable-wddx=shared "
    fi

    # --without-gdbm \
    # --with-qdbm=/usr \
    _phpextensions+="\
        --enable-dba=shared \
        --with-db4=/usr \
        --with-gdbm \
        --enable-inifile \
        --enable-flatfile \
        "

    _phpextensions+="\
        --with-imap=shared,/usr \
        --with-kerberos \
        --with-imap-ssl=yes \
        "
    # interbase pdo_firebird
    # requires: libfbclient    
    _phpextensions+=" --with-pdo-firebird=shared,/usr "
    if ((_build_interbase)); then
        _phpextensions+=" --with-interbase=shared,/usr "
    fi

    # pgsql pdo_pgsql
    _phpextensions+="\
        --with-pgsql=shared,/usr \
        --with-pdo-pgsql=shared,/usr \
        "
    _phpextensions+="\
        --enable-soap=shared \
        "
    if ((_phpbase < 74)); then
        _phpextensions+=" --with-libxml-dir=/usr "        
    fi
    
    if ((_build_opcache)); then
        _phpextensions+="\
            --enable-opcache \
            --enable-huge-code-pages \
            "
    fi

    if ((_build_mcrypt)); then
        _phpextensions+=" --with-mcrypt=shared "
    fi

    if ((_build_xmlrpc)); then
        _phpextensions+=" --with-xmlrpc=shared "
    fi
    
 
    if ((_build_sodium)); then
        _phpextensions+=" --with-sodium=shared "
    fi
    
    _phpextensions+=" --enable-mbstring=shared "
    
    if ((_phpbase > 53)); then
        # 5.3 fails to be built with mbregex
        _phpextensions+=" --enable-mbregex "
    fi
    if ((_phpbase < 74)); then
        _phpextensions+=" --enable-mbregex-backtrack "
    fi
    # pdo_dblib mssql modules
    _phpextensions+=" --with-pdo-dblib=shared,/usr "
    if ((_build_mssql)); then
        _phpextensions+=" --with-mssql=shared,/usr "
    fi    
    if ((_phpbase >= 50 && _phpbase <= 54)); then
        _phpextensions+=" --with-icu-dir=/${_php5_icu} "
    else
        _phpextensions+=" --disable-rpath "
    fi

    local _phpextensions_fpm="\
        --with-fpm-user=${_fpm_user} \
        --with-fpm-group=${_fpm_group} \
        "
    if ((_phpbase > 54)); then
        # Systemd support for fpm notifications is broken for PHP > 5.4
        _phpextensions_fpm+=" --with-fpm-systemd "
    fi
    if ((_phpbase > 55)); then
        _phpextensions_fpm+=" --with-fpm-acl "
    fi
        
    local _ldflags=''
    if ((_phpbase >= 50 && _phpbase <= 54)); then
        _ldflags="-Wl,-rpath=$ORIGIN/${_php5_icu}"
    fi
    
    if [[ ! -z "${_new_flags}" ]]; then
        CPPFLAGS+=" $_new_flags "
    fi
    if [[ ! -z "${_ldflags}" ]]; then
        LDFLAGS+=" $_ldflags "
    fi
        
    echo "[DEBUG] CPPFLAGS ${_new_flags}"
    echo "[DEBUG] LDGFLAGS ${_ldflags}"
    echo "[DEBUG] PHPCONF  ${_phpconfig}" | sed -E 's|[ \t]+|\n|g';
    echo "[DEBUG] PHPEXT ${_phpextensions}" | sed -E 's|[ \t]+|\n|g';
    echo "[DEBUG] FPMEXT ${_phpextensions_fpm}" | sed -E 's|[ \t]+|\n|g';   
    #echo "[DEBUG] Build vars:\n $(declare -p | grep _build_ | grep -v lint_package_functions)"
    
    if [[ ! -d "build" ]]; then
        mkdir "build"
    fi
    
    pushd "build"
    if [[ -L configure ]]; then
        rm configure
    fi
    ln -s "../php-${pkgver}/configure"
    popd
    if (( ! _build_per_sapi )); then
        # SAPIs: cli+cgi+fpm+embed
        pushd "build"
            ./configure ${_phpconfig} \
                --enable-cgi \
                --enable-fpm \
                ${_phpextensions_fpm} \
                --enable-embed=shared \
                ${_phpextensions}
            make
        popd
    else
        # Per sapi build: cli,cgi,fpm,embed

        # cli
        pushd "build"
            ./configure ${_phpconfig} \
                --disable-cgi \
                ${_phpextensions}
            make
        popd
        # cgi
        cp -Ta build build-cgi
        pushd build-cgi
            ./configure ${_phpconfig} \
                --disable-cli \
                --enable-cgi \
                ${_phpextensions}
            make
        popd

        # fpm
        cp -Ta build build-fpm
        pushd build-fpm
            ./configure ${_phpconfig} \
                --disable-cli \
                --enable-fpm \
                ${_phpextensions_fpm} \
                ${_phpextensions}
            make
        popd


        # embed
        cp -Ta build build-embed
        pushd build-embed
            ./configure ${_phpconfig} \
                --disable-cli \
                --enable-embed=shared \
                ${_phpextensions}
            make
        popd
    fi

    # apache build
    cp -a "build" "build-apache"
    pushd "build-apache"
        ./configure ${_phpconfig} \
            --with-apxs2 \
            ${_phpextensions}
        make
    popd

    # phpdbg build
    if ((_build_phpdbg)); then
        cp -a "build" "build-phpdbg"
        pushd "build-phpdbg"
            ./configure ${_phpconfig} \
                --enable-phpdbg \
                ${_phpextensions}
            make
        popd
    fi

    # PEAR build
    if ((_build_pear)); then
        cp -a "build" "build-pear"
        # Pear can't be built properly with shared xml
        local _ext_pear=$(echo ${_phpextensions} | sed 's/--enable-xml=shared/--enable-xml/g')
        export PEAR_INSTALLDIR="/usr/share/php${_phpbase}${_suffix}/pear"
        pushd "build-pear"
            ./configure ${_phpconfig} \
                --disable-cgi \
                --with-pear \
                ${_ext_pear}
            make
        popd
    fi
    unset EXTENSION_DIR
}

check() {
    pushd "php-${pkgver}"
    # Check if sendmail was configured correctly (FS#47600)
    ../build/sapi/cli/php -n -r 'echo ini_get("sendmail_path");' | grep -q '/usr/bin/sendmail'

    export REPORT_EXIT_STATUS=1
    export NO_INTERACTION=1
    export SKIP_ONLINE_TESTS=1
    export SKIP_SLOW_TESTS=1

    if ((_phpbase <= 54)); then
        TEST_PHP_EXECUTABLE="../build/sapi/cli/php" \
            ../build/sapi/cli/php -n run-tests.php -n {tests,Zend}
    elif ((_phpbase >= 55 && _phpbase < 73)); then
        ../build/sapi/cli/php -n run-tests.php -n -P {tests,Zend}
    elif ((73 == _phpbase)); then
        export TESTS='tests Zend'
        make test   
    elif ((_phpbase > 73)); then
        export TEST_PHP_ARGS="-j$(nproc)"
        export TESTS='tests Zend'
        make test            
    fi  
    popd    
}

# Custom code
_install_module_ini() {
    local extension=$(echo "${1}" | sed 's/\.so//')
    local priority="${_priority_default}"
    case "${extension}" in
        "json") 
            priority="${_priority_json}"
            ;;
        "xml")
            priority="${_priority_xml}"
            ;;
        "mysqlnd")
            priority="${_priority_mysqlnd}"
            ;;
        "pdo")
            priority="${_priority_pdo}"
            ;;
        "opcache")
            priority="${_priority_opcache}"
            ;;
    esac
    local extension_type="extension"
    case "${extension}" in
        "opcache" | "xdebug")
            extension_type="zend_extension"
            ;;
        "recode")
            extension_type=";extension"
            ;;
    esac
    
    if [[ ! -d "${pkgdir}/etc/php${_phpbase}${_suffix}/conf.d" ]]; then
        mkdir -p "${pkgdir}/etc/php${_phpbase}${_suffix}/conf.d"
    fi
    echo "${extension_type}=${extension}.so" > "${pkgdir}/etc/php${_phpbase}${_suffix}/conf.d/${priority}-${extension}.ini"
    chmod 0644 "$pkgdir/etc/php${_phpbase}${_suffix}/conf.d/${priority}-${extension}.ini"
    _last_priority=${priority}
    _last_extension=${extension}
}

_install_module_so() {
    install -D -m755 "./build/modules/${1}.so" "${pkgdir}/usr/lib/php${_phpbase}${_suffix}/modules/${1}.so";
}

_install_module() {
    _install_module_so "${1}"
    _install_module_ini "${1}"
}
# Custom code end


package_php%PHPBASE%%SUFFIX%() {
    # Binary names
    pkgdesc='A general-purpose scripting language that is especially suited to web development'
    depends=('libxml2' 'pcre')
    if ((_phpbase >= 53 && _phpbase <= 54)); then
        depends+=("php5-libs")
    fi
    backup=("etc/php${_phpbase}${_suffix}/php.ini")
    #provides=("php${_phpbase}${_suffix}=${pkgver}")
    pushd "build"
    make -j1 INSTALL_ROOT=${pkgdir} install-{modules,build,headers,programs,pharcmd}

    install -D -m644 "../php-${pkgver}/php.ini-production" "${pkgdir}/etc/php${_phpbase}${_suffix}/php.ini"
    install -d -m755 "${pkgdir}/etc/php${_phpbase}${_suffix}/conf.d/"

    pushd "${pkgdir}/usr/lib/php${_phpbase}${_suffix}/modules/"
        # remove static modules
        rm -f *.a        
        # remove modules provided by sub packages
        rm -f {enchant,imap,intl,pspell,snmp,tidy,curl,ldap,bz2,bcmath,soap,zip,gmp,dba,opcache,json,gd,mcrypt,sodium,recode}.so
        # dblib package
        rm -rf {pdo_dblib,mssql}.so
        # xml package
        rm -f {dom,simplexml,xml,xmlreader,xmlwriter,xsl,wddx,xmlrpc}.so
        # PostgreSQL
        rm -f {pgsql,pdo_pgsql}.so
        # ODBC
        rm -f {odbc,pdo_odbc}.so
        # SQLite
        rm -f {pdo_sqlite,sqlite3}.so
        # pdo_firebird
        rm -f {pdo_firebird.so,interbase.so}
        # MySQL modules
        rm -f {mysqli,pdo_mysql,mysqlnd,mysql}.so
        
        # Install COMMON modules
        for i in *.so; do
            _install_module_ini "${i}"
        done
    popd

    # remove empty directory
    rmdir "${pkgdir}/usr/include/php/include"

    # move include directory
    mv "${pkgdir}/usr/include/php" "${pkgdir}/usr/include/php${_phpbase}${_suffix}"
    
    # Link to phar
    ln -sf "${name_phar}.phar" "${pkgdir}/usr/bin/${name_phar}"

    # rename executables
    if [[ -f "${pkgdir}/usr/bin/phar.phar" ]]; then
        mv "${pkgdir}/usr/bin/phar.phar" "${pkgdir}/usr/bin/${name_phar}.phar"
    fi

    # rename man pages
    if [[ -f "${pkgdir}/usr/share/man/man1/phar.1" ]]; then
        mv "${pkgdir}/usr/share/man/man1/phar.1" \
            "${pkgdir}/usr/share/man/man1/${name_phar}.1"
    fi

    if [[ -f "${pkgdir}/usr/share/man/man1/phar.phar.1" ]]; then
        mv "${pkgdir}/usr/share/man/man1/phar.phar.1" \
            "${pkgdir}/usr/share/man/man1/phar.${name_phar}.1"
    fi
    
    # kill phar symlink in old php builds
    rm -f "${pkgdir}/usr/bin/phar"
    
    # fix paths in executables
    echo "[SED] ${pkgdir}/usr/bin/${name_phpize}"
    sed -i "/^includedir=/c \includedir=/usr/include/php${_phpbase}${_suffix}" "${pkgdir}/usr/bin/${name_phpize}"
    echo "[SED] ${pkgdir}/usr/bin/${name_phpconfig}"
    sed -i "/^include_dir=/c \include_dir=/usr/include/php${_phpbase}${_suffix}" "${pkgdir}/usr/bin/${name_phpconfig}"

    echo "[SED] Sed for ${pkgdir}/usr/lib/php${_phpbase}${_suffix}/build/phpize.m4"
    # make phpize use correct php-config
    sed -i "/^\[  --with-php-config=/c \[  --with-php-config=PATH  Path to php-config [${name_phpconfig}]], ${name_phpconfig}, no)" "${pkgdir}/usr/lib/php${_phpbase}${_suffix}/build/phpize.m4"            
    # popd
    popd
}
# End install common

# Cli
package_php%PHPBASE%-cli%SUFFIX%() {
    pkgdesc="cli (command-line executable) version for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    pushd "build"
    make -j1 INSTALL_ROOT="${pkgdir}" install-cli
    popd
}
# End cli

# CGI
package_php%PHPBASE%-cgi%SUFFIX%() {
    pkgdesc="CGI and FCGI SAPI for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php${_phpbase}${_suffix}-cgi=${pkgver}")
    if ((_build_per_sapi)); then
        pushd "build-cgi"
    else
        pushd "build"
    fi
    case "${_phpbase}" in
        53)
            install -D -m755 sapi/cgi/php-cgi "${pkgdir}/usr/bin/php${_phpbase}${_suffix}-cgi"
            ;;
        *)
            make -j1 INSTALL_ROOT="${pkgdir}" install-cgi
            ;;
    esac
    popd
}
# End CGI

package_php%PHPBASE%-apache%SUFFIX%() {
    pkgdesc="Apache SAPI for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'apache')
    backup=("${apache_cfg}/${name_apache_module_conf}")
    #provides=("php${_phpbase}${_suffix}-apache=${pkgver}")
    echo "# End of LoadModule in httpd.conf - see ArchWiki Apache HTTP Server"
    echo "LoadModule ${name_mod_php} modules/libphp${_phpbase}${_suffix}.so"
    echo "AddHandler ${name_script_php} .php"
    echo "# End of Include List"
    echo "Include conf/extra/${name_apache_module_conf}"
    install -D -m755 "build-apache/libs/${name_libapache_source}" "${pkgdir}/usr/lib/httpd/modules/libphp${_phpbase}${_suffix}.so"
    install -D -m644 "php-apache.conf" "${pkgdir}/${apache_cfg}/${name_apache_module_conf}"
    echo "Sed for ${pkgdir}/${apache_cfg}/${name_apache_module_conf}"
    sed -e "s#%MODULE%#${name_mod_php}#" \
        -i "${pkgdir}/${apache_cfg}/${name_apache_module_conf}"
}

package_php%PHPBASE%-fpm%SUFFIX%() {
    pkgdesc="FastCGI Process Manager for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'systemd')
    backup=("etc/php${_phpbase}${_suffix}/php-fpm.conf")
    if ((_phpbase>=70)); then
        backup+=("etc/php${_phpbase}${_suffix}/php-fpm.d/www.conf")
    fi
    options=('!emptydirs')

    if ((_build_per_sapi)); then
        pushd "build-fpm"
    else
        pushd "build"
    fi
    case "${_phpbase}" in
        53)
            install -d -m755 "${pkgdir}/usr/bin"
            install -D -m755 sapi/fpm/php-fpm "${pkgdir}/usr/bin/${name_php_fpm}"
            install -D -m644 sapi/fpm/php-fpm.8 "${pkgdir}/usr/share/man/man8/${name_php_fpm}.8"
            install -D -m644 sapi/fpm/php-fpm.conf "${pkgdir}/etc/php${_phpbase}${_suffix}/php-fpm.conf"
            install -d -m755 "${pkgdir}/etc/php${_phpbase}${_suffix}/fpm.d"
            ;;
        *)
            make -j1 INSTALL_ROOT="${pkgdir}" install-fpm
            ;;
    esac

    install -D -m644 "sapi/fpm/php-fpm.service" "${pkgdir}/usr/lib/systemd/system/${name_php_fpm}.service"
    echo "d /run/${name_php_fpm} 755 root root" > php-fpm.tmpfiles
    install -D -m644 "php-fpm.tmpfiles" "${pkgdir}/usr/lib/tmpfiles.d/${name_php_fpm}.conf"
    popd
}

package_php%PHPBASE%-embed%SUFFIX%() {
    pkgdesc="Embedded PHP SAPI library for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'libsystemd')
    options=('!emptydirs')
    if ((_build_per_sapi)); then
        pushd "build-embed"
    else
        pushd "build"
    fi
    patchelf --set-soname "libphp${_phpbase}${_suffix}.so" "libs/${name_libembed_source}"
    case "${_phpbase}" in
        53)
            install -D -m755 "libs/${name_libembed_source}" "${pkgdir}/usr/lib/libphp${_phpbase}${_suffix}.so"
            install -D -m644 "../php-${pkgver}/sapi/embed/php_embed.h" "${pkgdir}/usr/include/php${_phpbase}${_suffix}/sapi/embed/php_embed.h"
            ;;
        *)
            make -j1 INSTALL_ROOT="${pkgdir}" PHP_SAPI=embed install-sapi
            mv "${pkgdir}/usr/lib/${name_libembed_source}" "${pkgdir}/usr/lib/libphp${_phpbase}${_suffix}.so"
            ;;
    esac
    popd
}


package_php%PHPBASE%-phpdbg%SUFFIX%() {
    pkgdesc="Interactive PHP debugger for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    options=('!emptydirs')
    #provides=("php${_phpbase}${_suffix}-phpdbg=${pkgver}")

    pushd "build-phpdbg"
    make -j1 INSTALL_ROOT="${pkgdir}" install-phpdbg
    popd
}

package_php%PHPBASE%-pear%SUFFIX%() {
    pkgdesc="PHP Extension and Application Repository for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" "php${_phpbase}-xml${_suffix}")
    #provides=("${_pkgbase}-pear=$pkgver")
    backup=("etc/php${_phpbase}${_suffix}/pear.conf")
    #
    pushd "build-pear"

    make install-pear INSTALL_ROOT="${pkgdir}"

    # remove unneeded files
    rm -rf "${pkgdir}"/.{channels,depdb,depdblock,filemap,lock,registry}

    # rename binaries
    for i in pear peardev pecl; do
        echo "Moving ${pkgdir}/usr/bin/${i} => ${pkgdir}/usr/bin/${pkgbase/php/$i}"
        mv "${pkgdir}/usr/bin/${i}" "${pkgdir}/usr/bin/${pkgbase/php/$i}"
        # fix hardcoded php paths in pear
        sed -i "s|/usr/bin/php|/usr/bin/php${_phpbase}${_suffix}|g" "${pkgdir}/usr/bin/${pkgbase/php/$i}"
        sed -i "s|PHP=php|PHP=${_phpbase}${_suffix}|g" "${pkgdir}/usr/bin/${pkgbase/php/$i}"            
    done
    # fix pear.conf with unserialize
    ./sapi/cli/php ../pear-config-patcher.php "${pkgdir}/etc/php${_phpbase}${_suffix}/pear.conf" "/usr/bin/php${_phpbase}${_suffix}" "${_phpbase}${_suffix}"

    #popd
    popd
}

package_php%PHPBASE%-dblib%SUFFIX%() {  
    depends=("php${_phpbase}${_suffix}" 'freetds')
    provides=(
        "php${_phpbase}${_suffix}-sybase=${pkgver}"    
    )
   _install_module pdo_dblib
    if ((_build_mssql)); then        
        _install_module mssql
        provided+=("php${_phpbase}${_suffix}-mssql=${pkgver}")
        _desc="pdo_dblib module for php${_phpbase}${_suffix}"
    else
        _desc="mssql and pdo_dblib modules for php${_phpbase}${_suffix}"
    fi
    pkgdesc="${_desc}${_phpbase}${_suffix}"
}

package_php%PHPBASE%-enchant%SUFFIX%() {
    pkgdesc="enchant module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'enchant')
    #provides=("php%PHPBASE%-enchant=${pkgver}" "php-enchant=${pkgver}")
    _install_module enchant
}

package_php%PHPBASE%-gd%SUFFIX%() {
    pkgdesc="gd module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'gd')
    if ((_build_bundled_gd)); then
        depends+=('libxpm' 'libpng' 'libjpeg')
    fi
    #provides=("php%PHPBASE%-gd=${pkgver}" "php-gd=${pkgver}")
    _install_module gd
}


package_php%PHPBASE%-imap%SUFFIX%() {
    pkgdesc="imap module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-imap=${pkgver}" "php-imap=${pkgver}")
   _install_module imap
}

package_php%PHPBASE%-intl%SUFFIX%() {
    pkgdesc="intl module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-intl=${pkgver}" "php-intl=${pkgver}")
    _install_module intl
}

package_php%PHPBASE%-mcrypt%SUFFIX%() {
    pkgdesc="mcrypt module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'libmcrypt')
    #provides=("php%PHPBASE%-mcrypt=${pkgver}" "php-mcrypt=${pkgver}")
   _install_module mcrypt
}

package_php%PHPBASE%-odbc%SUFFIX%() {
    pkgdesc="ODBC modules for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'unixodbc')
    #provides=("php%PHPBASE%-odbc=${pkgver}" "php-odbc=${pkgver}")
    _install_module odbc
    _install_module pdo_odbc
}

package_php%PHPBASE%-pgsql%SUFFIX%() {
    pkgdesc="PostgreSQL modules for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'postgresql-libs')
    #provides=("php${_phpbase}${_suffix}-pgsql=${pkgver}")
    _install_module pgsql
    _install_module pdo_pgsql
}

package_php%PHPBASE%-pspell%SUFFIX%() {
    pkgdesc="pspell module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'aspell')
    #provides=("php%PHPBASE%-pspell=${pkgver}" "php-pspell=${pkgver}")
    _install_module pspell
}

package_php%PHPBASE%-snmp%SUFFIX%() {
    pkgdesc="snmp module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'net-snmp')
    #provides=("php%PHPBASE%-snmp=${pkgver}" "php-snmp=${pkgver}")
    _install_module snmp
}

package_php%PHPBASE%-sqlite%SUFFIX%() {
    pkgdesc="sqlite module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'sqlite')
    #provides=("php%PHPBASE%-sqlite=${pkgver}" "php-sqlite=${pkgver}")
    _install_module sqlite3
    _install_module pdo_sqlite
}

package_php%PHPBASE%-tidy%SUFFIX%() {
    pkgdesc="tidy module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'tidy')
    #provides=("php%PHPBASE%-snmp=${pkgver}" "php-snmp=${pkgver}")
    _install_module tidy
}

package_php%PHPBASE%-xml%SUFFIX%() {
    pkgdesc="xml modules for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'libxslt' 'libxml2')
    provides=("php%PHPBASE%-xsl=${pkgver}" "${pkgname}-xsl=${pkgver}")
    replaces=("php%PHPBASE%-xsl")
    conflicts=("php%PHPBASE%-xsl")
    _install_module dom
    _install_module simplexml
    if ((_build_wddx)); then
        _install_module wddx
    fi
    _install_module xml
    _install_module xmlreader
    _install_module xmlwriter
    _install_module xsl
}

#if ((_build_xmlrpc)); then
package_php%PHPBASE%-xmlrpc%SUFFIX%() {
    pkgdesc="xmlrpc module for php${_phpbase}${_suffix}"
    #provides=("php%PHPBASE%-xmlrpc=${pkgver}" "php-xmlrpc=${pkgver}")
    depends=("php${_phpbase}${_suffix}")
    _install_module xmlrpc
}
#fi

package_php%PHPBASE%-soap%SUFFIX%() {
    pkgdesc="soap module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'libxml2')
    #provides=("php%PHPBASE%-soap=${pkgver}" "php-soap=${pkgver}")
    _install_module soap
}

package_php%PHPBASE%-zip%SUFFIX%() {
    pkgdesc="zip module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" 'libzip')
    #provides=("php%PHPBASE%-zip=${pkgver}" "php-zip=${pkgver}")
    _install_module zip
}


package_php%PHPBASE%-bcmath%SUFFIX%() {
    pkgdesc="bcmath module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-bcmath=${pkgver}" "php-bcmath=${pkgver}")
    _install_module bcmath
}

package_php%PHPBASE%-bz2%SUFFIX%() {
    pkgdesc="bz2 module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-bz2=${pkgver}" "php-bz2=${pkgver}")
    _install_module bz2
}

package_php%PHPBASE%-ldap%SUFFIX%() {
    pkgdesc="ldap module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-ldap=${pkgver}" "php-ldap=${pkgver}")
    _install_module ldap
}

package_php%PHPBASE%-curl%SUFFIX%() {
    pkgdesc="curl module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" "curl")
    #provides=("php%PHPBASE%-curl=${pkgver}" "php-curl=${pkgver}")
    _install_module curl
}

# gmp
package_php%PHPBASE%-gmp%SUFFIX%() {
    pkgdesc="gmp module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-gmp=${pkgver}" "php-gmp=${pkgver}")
    _install_module gmp
}
# End gmp

# Dba
package_php%PHPBASE%-dba%SUFFIX%() {
    pkgdesc="dba module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-dba=${pkgver}" "php-dba=${pkgver}")
    _install_module dba
}
# End dba

# Json
package_php%PHPBASE%-json%SUFFIX%() {
    pkgdesc="json module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    #provides=("php%PHPBASE%-json=${pkgver}" "php-json=${pkgver}")
    _install_module json
}
# End json

#if ((_build_recode)); then
# Recode
package_php%PHPBASE%-recode%SUFFIX%() {
    pkgdesc="recode module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    _install_module recode
}
# End recode
#fi

#if ((_build_sodium)); then
# Recode
package_php%PHPBASE%-sodium%SUFFIX%() {
    pkgdesc="sodium (libsodium) module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" "libsodium")
    _install_module sodium
}
# End recode
#fi

#if ((_build_opcache)); then
# Opcache
package_php%PHPBASE%-opcache%SUFFIX%() {
    pkgdesc="opcache zend module for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    _install_module opcache
}
# End opcache
#fi

# Interbase modules
package_php%PHPBASE%-interbase%SUFFIX%() {
    pkgdesc="Interbase modules for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}" "libfbclient")
    #backup=()
    if ((_build_interbase)); then
        _install_module interbase
    fi    
    _install_module pdo_firebird
}
# End interbase

# MySQL modules
package_php%PHPBASE%-mysql%SUFFIX%() {
    pkgdesc="MySQL modules for php${_phpbase}${_suffix}"
    depends=("php${_phpbase}${_suffix}")
    _install_module mysqlnd
    _install_module mysqli
    _install_module pdo_mysql
    if ((_build_outdated_mysql)); then
        _install_module mysql
    fi
}
# End mysql
