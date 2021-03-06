{ lib, writeText, buildPythonPackage, isPy3k, fetchPypi
, openldap, cyrus_sasl, openssl, pytest, pyasn1 }:

buildPythonPackage rec {
  pname = "python-ldap";
  version = "2.5.2";
  name = "${pname}-${version}";
  disabled = isPy3k;

  src = fetchPypi {
    inherit pname version;
    sha256 = "b8c134dfedaef0e6ff4a4b94277708dcadb758b448905a83b8946df077356ed2";
  };

  checkInputs = [ pytest pyasn1 ];

  checkPhase = ''
    # Needed by tests to setup a mockup ldap server.
    export BIN="${openldap}/bin"
    export SBIN="${openldap}/bin"
    export SLAPD="${openldap}/libexec/slapd"
    export SCHEMA="${openldap}/etc/schema"

    # AssertionError: expected errno=107, got 57 -> nix sandbox related ?
    py.test -k 'not TestLdapCExtension and \
                not Test01_SimpleLDAPObject and \
                not Test02_ReconnectLDAPObject' Tests/*.py
  '';

  patches = lib.singleton (writeText "avoid-syslog.diff" ''
    diff a/Lib/slapdtest.py b/Lib/slapdtest.py
    --- a/Lib/slapdtest.py
    +++ b/Lib/slapdtest.py
    @@ -60,7 +60,8 @@ def combined_logger(
                 pass
         # for writing to syslog
         new_logger = logging.getLogger(log_name)
    -    if sys_log_format:
    +    # /dev/log does not exist in nix build environment.
    +    if False:
             my_syslog_formatter = logging.Formatter(
                 fmt=' '.join((log_name, sys_log_format)))
             my_syslog_handler = logging.handlers.SysLogHandler(
  '');

  NIX_CFLAGS_COMPILE = "-I${cyrus_sasl.dev}/include/sasl";
  propagatedBuildInputs = [openldap cyrus_sasl openssl];
}
