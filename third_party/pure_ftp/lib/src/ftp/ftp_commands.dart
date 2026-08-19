// ignore_for_file: constant_identifier_names,

/// More information available at https://en.wikipedia.org/wiki/List_of_FTP_commands
enum FtpCommand {
  ///Abort an active file transfer.
  ABOR,

  ///Account information.
  ACCT,

  ///Authentication/Security Data
  ADAT,

  ///Allocate sufficient disk space to receive a file.
  ALLO,

  ///Append (with create)
  APPE,

  ///Authentication/Security Mechanism
  AUTH,

  ///Get the available space
  AVBL,

  ///Clear Command Channel
  CCC,

  ///Change to Parent Directory.
  CDUP,

  ///Confidentiality Protection Command
  CONF,

  ///Client / Server Identification
  CSID,

  ///Change working directory.
  CWD,

  ///Delete file.
  DELE,

  ///Get the directory size
  DSIZ,

  ///Privacy Protected Channel
  ENC,

  ///Specifies an extended address and port to which the server should connect.
  EPRT,

  ///Enter extended passive mode.
  EPSV,

  ///Get the feature list implemented by the server.
  FEAT,

  ///Returns usage documentation on a command if specified, else a general help document is returned.
  HELP,

  ///Identify desired virtual host on server, by name.
  HOST,

  ///Language Negotiation
  LANG,

  ///Returns information of a file or directory if specified, else information of the current working directory is returned.
  LIST,

  ///Specifies a long address and port to which the server should connect.
  LPRT,

  ///Enter long passive mode.
  LPSV,

  ///Return the last-modified time of a specified file.
  MDTM,

  ///Modify the creation time of a file.
  MFCT,

  ///Modify fact (the last modification time, creation time, UNIX group/owner/mode of a file).
  MFF,

  ///Modify the last modification time of a file.
  MFMT,

  ///Integrity Protected Command
  MIC,

  ///Make directory.
  MKD,

  ///Lists the contents of a directory in a standardized machine-readable format.
  MLSD,

  ///Provides data about exactly the object named on its command line in a standardized machine-readable format.
  MLST,

  ///Sets the transfer mode (Stream, Block, or Compressed).
  MODE,

  ///Returns a list of file names in a specified directory.
  NLST,

  ///No operation (dummy packet; used mostly on keepalives).
  NOOP,

  ///Select options for a feature (for example OPTS UTF8 ON).
  OPTS,

  ///Authentication password.
  PASS,

  ///Enter passive mode.
  PASV,

  ///Protection Buffer Size
  PBSZ,

  ///Specifies an address and port to which the server should connect.
  PORT,

  ///Data Channel Protection Level.
  PROT,

  ///Print working directory. Returns the current directory of the host.
  PWD,

  ///Disconnect.
  QUIT,

  ///Re initializes the connection.
  REIN,

  ///Restart transfer from the specified point.
  REST,

  ///Retrieve a copy of the file
  RETR,

  ///Remove a directory.
  RMD,

  ///Remove a directory tree
  RMDA,

  ///Rename from.
  RNFR,

  ///Rename to.
  RNTO,

  ///Sends site specific commands to remote server (like SITE IDLE 60 or SITE UMASK 002). Inspect SITE HELP output for complete list of supported commands.
  SITE,

  ///Return the size of a file.
  SIZE,

  ///Mount file structure.
  SMNT,

  ///Use single port passive mode (only one TCP port number for both control connections and passive-mode data connections)
  SPSV,

  ///Returns information on the server status, including the status of the current connection
  STAT,

  ///Accept the data and to store the data as a file at the server site
  STOR,

  ///Store file uniquely.
  STOU,

  ///Set file transfer structure.
  STRU,

  ///Return system type.
  SYST,

  ///Get a thumbnail of a remote image file
  THMB,

  ///Sets the transfer mode (ASCII/Binary).
  TYPE,

  ///Authentication username.
  USER,

  ///Change to the parent of the current working directory
  XCUP,

  ///Make a directory
  XMKD,

  ///Print the current working directory
  XPWD,

  ///Remove the directory
  XRMD,

  ///Send, mail if cannot
  XSEM,

  ///Send to terminal
  XSEN;

  @override
  String toString() => name;
}
