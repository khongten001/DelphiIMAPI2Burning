unit UnBurningUtility;

interface

uses IMAPI2_TLB,IMAPI2FS_TLB,Winapi.Windows,UnBurningUtility.Types,UnBurningUtility.resource,
     Vcl.ImgList,Vcl.graphics,System.SysUtils,System.Classes,cxImageComboBox,
     Winapi.ActiveX,Vcl.OleServer,WinApi.Messages,AxCtrls,
     vcl.controls,Winapi.ShellApi,vcl.Forms,System.Variants,System.Win.ComObj;

const
  Win32ImportSuffix = {$IFDEF Unicode}'W'{$ELSE}'A'{$ENDIF};
  DEFAULT_MAX_RETRY = 6;

  TIPO_SUPPORT_UNKNOWN            = 0;
  TIPO_SUPPORT_CD                 = 1;
  TIPO_SUPPORT_DVD                = 2;
  TIPO_SUPPORT_BDR                = 4;
  TIPO_SUPPORT_ISO                = 5;
  TIPO_SUPPORT_DVD_DL             = 10;

  function GetVolumeNameForVolumeMountPointA(lpszVolumeMountPoint: PAnsiChar;lpszVolumeName: PAnsiChar; cchBufferLength: DWORD): BOOL; stdcall; external 'kernel32.dll';
  function GetVolumeNameForVolumeMountPointW(lpszVolumeMountPoint: PWideChar;lpszVolumeName: PWideChar; cchBufferLength: DWORD): BOOL; stdcall; external 'kernel32.dll';
  function GetVolumeNameForVolumeMountPoint(lpszVolumeMountPoint: PChar;lpszVolumeName: PChar; cchBufferLength: DWORD): BOOL; stdcall; external 'kernel32.dll' name 'GetVolumeNameForVolumeMountPoint' + Win32ImportSuffix;
  Function SHCreateStreamOnFileEx( pszFile: PWChar; grfMode:DWORD; dwAttributes:DWORD;fCreate:BOOL; pstmTemplate:IStream; var ppstm:IStream):DWORD;stdcall; external 'shlwapi.dll' name 'SHCreateStreamOnFileEx';

type
  /// <summary>
  /// Event that is fired to report the progress of the burning operation.
  /// </summary>
  /// <param name="Sender">The object that raised the event.</param>
  /// <param name="SInfo">The current status message.</param>
  /// <param name="SPosition">The current position in the operation.</param>
  /// <param name="RefreshPosition">Whether or not the progress bar should be updated.</param>
  /// <param name="aAbort">Whether or not the burning operation should be aborted.</param>
  /// <param name="iType">The type of progress being reported.</param>
  /// <param name="AllowAbort">Whether or not the user is allowed to abort the operation.</param>
  TOnProgressBurn  = procedure(Sender:Tobject;Const SInfo:String;SPosition :Int64;RefreshPosition,aAbort:Boolean;iType:integer;AllowAbort:Boolean) of OBject;

  ///<summary>
  ///Type for logging events.
  ///</summary>
  ///<param name="aFunctionName">Name of the function being logged.</param>
  ///<param name="aDescriptionName">Description of the event being logged.</param>
  ///<param name="Level">Level of the logging event (e.g. Information, Warning, Error).</param>
  ///<param name="IsDebug">Whether the log event is for debugging purposes.</param>
  ///<remarks>
  ///This type defines a procedure for handling logging events. It takes in the name of the function being logged,
  ///a description of the event being logged, the level of the logging event (e.g. Information, Warning, Error), 
  ///and a flag indicating whether the log event is for debugging purposes. 
  ///</remarks>
  TOnLog           = procedure(Const aFunctionName,aDescritionName:String;Level:TpLivLog;IsDebug:Boolean=False)of OBject;
  
  ///<summary>
  /// Class that encapsulates burning and erasing functions using the IMAPI2 interface.
  ///</summary>  
  TBurningTool = class(TObject)
  private
    FListaDriveCD           : TStringList;
    FCancelWriting          : Boolean;
    FListaDriveDVD          : TStringList;
    FListaDriveDVD_DL       : TStringList;
    FListaDriveBDR          : TStringList;
    FListaDriveCD_DL        : TStringList;
    FDiriverList            : TStringList;
    FimgListSysSmall        : TImageList;
    FWriting                : Boolean;
    FLastuniqueId           : WideString;
    FDiscMaster             : TMsftDiscMaster2;
    FDiscRecord             : TMsftDiscRecorder2;
    FOnProgressBurn         : TOnProgressBurn;
    FAbort                  : Boolean;
    FCurrentWriter          : TMsftDiscFormat2Data;
    FOnLog                  : TOnLog;
    FEraseCDAuto            : Boolean;
    FCanErase               : Boolean;
    ///<summary>
    /// Procedure to create a list of drives of a certain type.
    ///</summary>
    procedure BuildListDrivesOfType;

    ///<summary>
    /// Function to check if the system can burn CD.
    ///</summary>
    function GetCanBurnCD: Boolean;

    ///<summary>
    /// Function to check if the system can burn CD with double-layer support.
    ///</summary>
    function GetCanBurnCD_DL: Boolean;

    ///<summary>
    /// Function to check if the system can burn DVD.
    ///</summary>
    function GetCanBurnDVD: Boolean;

    ///<summary>
    /// Function to check if the system can burn DVD with double-layer support.
    ///</summary>
    function GetCanBurnDVD_DL: Boolean;

    ///<summary>
    /// Function to check if the system can burn DBR.
    ///</summary>
    function GetCanBurnDBR: Boolean;

    ///<summary>
    /// Function to check if the system can burn any type of media.
    ///</summary>
    function GetSystemCanBurn: Boolean;

    ///<summary>
    /// Activates the disk recorder with the specified index.
    ///</summary>
    /// <param name="aIdexDriver">The index of the disk recorder to activate.</param>
    /// <returns>True if the disk recorder is successfully activated, false otherwise.</returns>    
    function ActiveDiskRecorder(aIdexDriver: Integer): Boolean;
    
    ///<summary>
    /// Checks if the FDiscRecord object is assigned.
    ///</summary>
    /// <returns>True if the FDiscRecord object is assigned, false otherwise.</returns>
    function IntFRecordAssigned: Boolean;

    ///<summary>
    /// Checks if the FDiscMaster object is assigned.
    ///</summary>
    /// <returns>True if the FDiscMaster object is assigned, false otherwise.</returns>
    function IntFDiskMasterAssigned: Boolean;
    
    ///<summary>
    /// Checks if the aDataWriter parameter is assigned to FDataWriter object.
    ///</summary>
    /// <param name="aDataWriter">The object to check if it's assigned to FDataWriter.</param>
    /// <returns>True if aDataWriter is assigned to FDataWriter, false otherwise.</returns>
    function IntFWriterAssigned(var aDataWriter: TMsftDiscFormat2Data): Boolean;

    ///<summary>
    /// Searches for the drive letter associated with the specified index.
    ///</summary>
    /// <param name="aIndex">The index of the drive to search for.</param>
    /// <param name="aLetterDrive">The drive letter associated with the specified index.</param>
    /// <returns>True if the drive letter is found, false otherwise.</returns>
    function FoundLetterDrive(aIndex: Integer; var aLetterDrive: String): Boolean;

    ///<summary>
    /// Checks if the specified drive supports the specified type of write operation.
    ///</summary>
    /// <param name="aDriveIndex">The index of the drive to check.</param>
    /// <param name="aSupportType">The type of support type to check for.</param>
    /// <returns>True if the drive supports the specified support type, false otherwise.</returns>
    function IsDriverRW(aDriveIndex: Integer; aSupportType: Integer): Boolean;

    ///<summary>
    /// Checks the media status and availability for writing using the specified driver index and check status array.
    ///</summary>
    ///<param name="aDataWriter">A reference to the TMsftDiscFormat2Data object.</param>
    ///<param name="aIndexDriver">The index of the driver to use for checking the media.</param>
    ///<param name="aCheckStatus">An array of Word values representing the check status.</param>
    ///<param name="aErrorDisc">A reference to a boolean value indicating if there was an error with the disc.</param>
    ///<param name="aCurrentStatus">A reference to a Word value representing the current status of the media.</param>
    ///<returns>A boolean value indicating whether the media status and availability check was successful.</returns>    
    function CheckMedia(var aDataWriter:TMsftDiscFormat2Data;aIndexDriver: integer;aCheckStatus : Array of Word;var aErrorDisc:boolean;var aCurrentStatus:Word): Boolean;

    ///<summary>
    ///Checks if the media in the specified drive is blank.
    ///</summary>
    ///<param name="aDataWriter">A reference to the TMsftDiscFormat2Data object representing the disc to check.</param>
    ///<param name="aIdexDriver">The index of the drive to check.</param>
    ///<param name="aErrorMedia">A boolean value that indicates if there was an error while checking the disc. If set to true, the media is not considered blank.</param>
    ///<returns>True if the media is blank, False otherwise.</returns>    
    function isDiskEmpty(var aDataWriter:TMsftDiscFormat2Data;aIdexDriver:integer;var aErrorMedia : Boolean) : Boolean;

    /// <summary>
    /// Check if the disk is re-writable.
    /// </summary>
    /// <param name="aDataWriter">The data writer object.</param>
    /// <param name="aIdexDriver">The index of the selected driver.</param>
    /// <param name="aErrorMedia">The flag that indicates if there was an error while checking the media.</param>
    /// <returns>True if the disk is re-writable, False otherwise.</returns>    
    function isDiskWritable(var aDataWriter:TMsftDiscFormat2Data;aIdexDriver: integer;var aErrorMedia: Boolean): Boolean;

    /// <summary>
    /// Checks if the media in the disc drive supports the given support type
    /// and returns whether it is read-write capable and provides a reference to 
    /// a data writer if it is.
    /// </summary>
    /// <param name="aIdexDriver">The index of the disc drive to check.</param>
    /// <param name="aSupportType">The support type to check for.</param>
    /// <param name="aIsRW">Returns true if the media is read-write capable.</param>
    /// <param name="aDataWriter">Returns a reference to a data writer if the media is 
    /// read-write capable, otherwise null.</param>
    /// <returns>True if the media supports the given support type, false otherwise.</returns>
    function CheckMediaBySupport(aIdexDriver, aSupportType: integer;var aIsRW:Boolean;var aDataWriter:TMsftDiscFormat2Data): Boolean;

    /// <summary>
    /// Checks if a disk is present on a given drive.
    /// </summary>
    /// <param name="aIdexDriver">The index of the drive to check.</param>
    /// <param name="aDataWriter">The writer object to use for the check.</param>
    /// <returns>True if a disk is present on the drive, False otherwise.</returns>    
    function DiskIsPresentOnDrive(aIdexDriver:Integer;var aDataWriter:TMsftDiscFormat2Data): Boolean;
    
    /// <summary>
    /// Raises the OnProgressBurn event to report the progress of the burning operation.
    /// </summary>
    /// <param name="aSInfo">The current status message.</param>
    /// <param name="aAllowAbort">Whether or not the user is allowed to abort the operation.</param>    
    procedure DoOnProgressBurnCustom(Const aSInfo: String;aAllowAbort:Boolean=True);
    
    ///<summary>
    /// Returns the label of a given drive type as a string. The function takes a single input parameter, aDriveChar, which is a string representing the drive letter. 
    /// The function first calls the Win32 API function SHGetFileInfo to retrieve information about the drive. 
    /// It then calls the Win32 API function GetVolumeInformation to retrieve volume information for the drive. 
    /// Finally, the function returns the label of the drive as a string.
    ///</summary>
    ///<param name="aDriveChar">A string representing the drive lette.</param>
    ///<returns>The label of the drive as a string</returns>     
    function GetDriveTypeLabel(Const aDriveChar: String): string;
    
    ///<summary>
    /// Checks if the provided profiles support rewritable drives and sets the corresponding output flags.
    ///</summary>
    ///<param name="aSupportedProfiles">A pointer to the array of supported profiles.</param>
    ///<param name="aWCd">Outputs true if the device is capable of writing CDs.</param>
    ///<param name="aWDVD">Outputs true if the device is capable of writing DVDs.</param>
    ///<param name="aWBDR">Outputs true if the device is capable of writing Blu-ray discs.</param>
    ///<param name="aWDvd_DL">Outputs true if the device is capable of writing double-layer DVDs.</param>
    ///<param name="awCD_DL">Outputs true if the device is capable of writing double-layer CDs.</param>    
    procedure IsWrittableDriver(aSupportedProfiles: PSafeArray; var aWCd, aWDVD,aWBDR,aWDvd_DL,awCD_DL: Boolean);
    
    ///<summary>
    /// Checks if the provided profiles support recordable drives and sets the corresponding output flags.
    ///</summary>
    ///<param name="aSupportedFeaturePages">A pointer to the array of supported feature page.</param>
    ///<param name="aWCd">Outputs true if the device is capable of writing CDs.</param>
    ///<param name="aWDVD">Outputs true if the device is capable of writing DVDs.</param>
    ///<param name="aWBDR">Outputs true if the device is capable of writing Blu-ray discs.</param>
    ///<param name="aWDvd_DL">Outputs true if the device is capable of writing double-layer DVDs.</param>
    ///<param name="awCD_DL">Outputs true if the device is capable of writing double-layer CDs.</param>        
    procedure IsRecordableDriver(aSupportedFeaturePages: PSafeArray; var aWCd,aWDVD, aWBDR,aWDvd_DL,awCD_DL: Boolean);
    
    /// <summary>
    /// Builds a list of driver types for a specified volume name.
    /// </summary>
    /// <param name="aVolumeName">The volume name to search for.</param>
    /// <param name="aWcd">Specifies if CD drives should be included.</param>
    /// <param name="aWdvd">Specifies if DVD drives should be included.</param>
    /// <param name="aWbdr">Specifies if Blu-ray drives should be included.</param>
    /// <param name="aWdvdDl">Specifies if dual-layer DVD drives should be included.</param>
    /// <param name="awCD_DL">Specifies if dual-layer CD drives should be included.</param>
    /// <param name="aIdx">The index of the volume name in the list.</param>
    procedure BuildListDriverType(aVolumeName: WideString; aWcd, aWdvd, aWbdr,awdvdDL,awCD_DL: Boolean; aIdx: Integer);

    /// <summary>
    ///     Sets the burn verification level for a given MsftDiscFormat2Data object.
    /// </summary>
    /// <param name="aDataWriter">The MsftDiscFormat2Data object to set the verification level for.</param>
    /// <param name="aVerificationLevel">The level of burn verification to set.</param>
    /// <returns>
    ///     Returns True if the burn verification level was set successfully, False otherwise.
    /// </returns>    
    function SetBurnVerification(var aDataWriter: TMsftDiscFormat2Data; aVerificationLevel: IMAPI_BURN_VERIFICATION_LEVEL): Boolean;
    
    /// <summary>
    /// Check if the necessary interfaces are assigned and if the specified drive is active.
    /// </summary>
    /// <param name="IndexDriver">Index of the drive to check</param>
    /// <returns>True if all interfaces are assigned and the specified drive is active, False otherwise</returns>    
    function CheckAssignedAndActivationDrive(IndexDriver: Integer): Boolean;
    
    ///<summary>
    /// Manages the insertion of a disk in the drive identified by the provided index and letter drive.
    /// If there is a valid and empty disk present, it returns True, otherwise, it prompts the user to insert an appropriate disk and returns False.
    ///</summary>
    ///<param name="aIdexDriver">The index of the driver to be checked.</param>
    ///<param name="aSupportType">The type of support the inserted disk must have.</param>
    ///<param name="aDataWriter">The data writer to be checked.</param>
    ///<param name="aLetterDrive">The letter of the drive to be checked.</param>
    ///<param name="aIRetry">The number of times the function has been called without success.</param>
    ///<returns>True if a valid and empty disk is present in the drive identified by the provided index and letter drive, False otherwise.</returns>    
    function MngInsertDisk(aIdexDriver, aSupportType: Integer;var aDataWriter: TMsftDiscFormat2Data; const aLetterDrive: String;var aIRetry:Integer): Boolean;

    ///<summary>
    /// This method creates a small system image list of icons.
    /// The image list will contain icons of small size that are associated with system objects, such as files and folders. 
    /// The "SHGetFileInfo" function is used to obtain system icon information, and the "TSHFileInfo" record is used to hold the retrieved information.
    /// The "SHGFI_SMALLICON" flag specifies that small icons should be retrieved, and the "SHGFI_SYSICONINDEX" flag specifies that system image indices should be retrieved. 
    /// The "SHGFI_PIDL" flag indicates that the function should use a pointer to an item identifier list (PIDL) instead of a path name. Finally, the "ShareImages" property is set to "True" so that multiple image lists can share the same underlying system image list handle, conserving system resources.
    ///</summary>    
    procedure CreateImageListIconSystem;
    
    ///<summary>
    ///  Creates lists of available drives by type for burning tool.
    ///</summary>
    ///<remarks>
    ///  This method initializes several string lists to hold the drive letters of available drives by type.
    ///  The lists include CD drives, DVD drives, dual-layer CD drives, dual-layer DVD drives, and Blu-ray drives.
    ///  The method also creates a general driver list for use in other parts of the burning tool.
    ///</remarks>    
    procedure CreateInterListDriveByType;
    ///<summary>
    /// Search for recordable drivers and builds internal lists a
    ///</summary>  
    procedure SearchRecordableDriver;
    
    ///<summary>
    ///  This procedure writes the ISO file to the given data writer.
    /// </summary>
    ///<param name="aDataWriter">
    ///  The data writer to write the ISO file.
    ///</param>
    ///<param name="aIndexDriver">
    ///  The index of the driver to write the ISO file.
    ///</param>
    ///<param name="aSupportType">
    ///  The support type of the driver to write the ISO file.
    ///</param>
    ///<param name="aCaptionDisk">
    ///  The caption of the disk to write the ISO file.
    ///</param>
    ///<param name="aPathIso">
    ///  The path of the ISO file to be written.
    ///</param>
    ///<param name="aStatusWrite">
    ///  The status of the writing operation.
    ///</param>
    ///<remarks>
    ///  If the ISO file could not be loaded, the procedure will exit without doing anything.
    ///</remarks>    
    procedure WriteIso(var aDataWriter: TMsftDiscFormat2Data;aIndexDriver,aSupportType:Integer; const aCaptionDisk,aPathIso: string;var aStatusWrite : TStatusBurn);

    /// <summary>
    /// Builds the specified TcxImageComboBoxItems with the items contained in the provided TStringList.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems to be built.</param>
    /// <param name="aDriverList">The TStringList containing the items to be added to the TcxImageComboBoxItems.</param>    
    procedure BuilcxComboBox(aItemsCxComboBox: TcximageComboBoxItems;aDriverList: TStringList);
    
    /// <summary>
    /// Gets the maximum write sectors per second supported by the specified driver and data writer.
    /// </summary>
    /// <param name="aDataWriter">The data writer object.</param>
    /// <param name="aIndexDriver">The index of the driver to check.</param>
    /// <param name="aSupportType">The type of write speed to check.</param>
    /// <returns>The maximum write sectors per second supported.</returns>    
    function GetMaxWriteSectorsPerSecondSupported(const aDataWriter: TMsftDiscFormat2Data; aIndexDriver,aSupportType: Integer): Integer;

    /// <summary>
    /// Cancel the current writing process.
    /// </summary>
    procedure CancelWriting;
    
    /// <summary>
    /// Gets the human-readable write speed string based on the number of sectors per second and the type of supported media.
    /// </summary>
    /// <param name="aSectorForSecond">The number of sectors per second.</param>
    /// <param name="aSupportType">The type of supported media (CD, DVD, DVD DL, BDR).</param>
    /// <returns>A human-readable write speed string.</returns>    
    function GetHumanSpeedWrite(aSectorForSecond: Integer;aSupportType:Integer): string;
    
    /// <summary>
    /// The WriteLog procedure logs a message through the FOnLog event, which is a user-defined event. 
    /// <param name="aFunctionName">The name of the function or procedure that generated the log message</param>
    /// <param name="aDescriptionName">the message to log</param>
    /// <param name="Level">the log level which is an enumeration that defines the severity level of the message</param>     
    /// <param name="IsDebug">is set to true, the message is logged only if the DEBUG conditional symbol is defined</param>
    /// </summary>
    procedure WriteLog(const aFunctionName,aDescriptionName: String; Level: TpLivLog;IsDebug: Boolean=False);

    ///<summary>
    /// This function converts a number of seconds into a double value representing the time in hours.
    ///</summary>    
    function SecondToTime(const aSeconds: Cardinal): Double;
    
    ///<summary>
    ///Event handler for IDiscFormat2Data update.
    ///Updates the progress of the burning process, and logs important information about the progress.
    ///</summary>
    ///<param name="ASender">The object that invoked this event handler.</param>
    ///<param name="object_">The IDiscFormat2Data object.</param>
    ///<param name="progress">The IDiscFormat2DataEventArgs object containing the progress information.</param>
    ///<remarks>This method is used to update the progress of a burning process using the IDiscFormat2Data interface. 
    ///It logs information about the progress, such as disk validation, disk formatting, laser calibration, disk writing, disk finalization, and disk verification. 
    ///The progress is reported using the FOnProgressBurn event.</remarks>    
    procedure MsftDiscFormat2DataUpdate(ASender: TObject; const object_,progress: IDispatch);
    
    ///<summary>
    /// Event handler for updating progress during disc erasing using the MsftEraseData object.
    ///</summary>
    ///<param name="ASender">The object that triggered the event.</param>
    ///<param name="object_">The IDispatch interface representing the MsftEraseData object.</param>
    ///<param name="elapsedSeconds">The number of seconds elapsed since the start of the erasing process.</param>
    ///<param name="estimatedTotalSeconds">The estimated total number of seconds required to complete the erasing process.</param>    
    procedure MsftEraseDataUpdate(ASender: TObject; const object_: IDispatch;elapsedSeconds, estimatedTotalSeconds: Integer);    
  public
    constructor Create;
    destructor Destroy; override;
    
    /// <summary>
    /// This function burns a disk image in ISO format.
    /// </summary>
    /// <param name="aIdexDriver">Index of the driver to use.</param>
    /// <param name="aSupportType">Type of the supported driver.</param>
    /// <param name="aSPathIso">Path of the ISO file to burn.</param>
    /// <param name="aCaptionDisk">Caption of the disk to burn.</param>
    /// <param name="aCheckDisk">If set to true, verifies the disk after the burning process.</param>
    /// <returns>Status of the burn process.</returns>    
    Function BurningDiskImage(aIdexDriver,aSupportType:Integer;Const aSPathIso,aCaptionDisk:String;aCheckDisk:Boolean): TStatusBurn;

    /// <summary>
    /// Ejects the CD/DVD drive with the specified index.
    /// </summary>
    /// <param name="aIdexDriver">The index of the CD/DVD drive to eject.</param>
    /// <returns>True if the operation was successful, False otherwise.</returns>    
    Function DriveEject(aIdexDriver:Integer) : Boolean;
    
    /// <summary>
    /// Erases a disk using the specified optical drive and support type.
    /// </summary>
    /// <param name="aIdexDriver">The index of the optical drive to use.</param>
    /// <param name="aSupportType">The support type to use for the erase operation.</param>
    /// <param name="aEject">Indicates whether to eject the disk after the erase operation is complete.</param>
    /// <returns>A Boolean value indicating whether the erase operation was successful.</returns>    
    function EraseDisk(aIdexDriver,aSupportType: Integer;aEject:Boolean):Boolean;
    
    /// <summary>
    /// Closes the tray of the specified optical drive.
    /// </summary>
    /// <param name="aIdexDriver">Index of the optical drive.</param>
    /// <returns>True if the operation was successful, False otherwise.</returns>    
    function CloseTray(aIdexDriver: Integer): Boolean;
    
    /// <summary>
    /// Gets the index of the CD-ROM drive with the specified letter.
    /// </summary>
    /// <param name="aLetter">The letter of the CD-ROM drive.</param>
    /// <returns>The index of the CD-ROM drive with the specified letter, or -1 if not found.</returns>    
    Function GetIndexCDROM(const aLetter:String):Integer;
    
    /// <summary>
    /// Cancel the current burning process.
    /// </summary>    
    procedure CancelBurning;
    
    ///<summary>
    ///Function to create an ISO image from a folder.
    ///</summary>
    ///<param name="aFolderToAdd">The folder path to create the ISO image from.</param>
    ///<param name="aVolumeName">The name of the volume.</param>
    ///<param name="aResultFile">The path and filename of the resulting ISO image.</param>
    ///<param name="aIMAPIDisc">The physical type of the media to use.</param>
    ///<returns>True if the ISO image is successfully created, False otherwise.</returns>    
    function CreateIsoImage(const aFolderToAdd: String; aVolumeName: String;const aResultFile: String; aIMAPIDisc: IMAPI_MEDIA_PHYSICAL_TYPE): Boolean;
    
    /// <summary>
    /// Retrieves the index of the system icon associated with the specified drive, and returns it as an integer.
    /// </summary>
    /// <param name="aDrive">A string representing the drive letter of the target drive.</param>
    /// <returns>An integer representing the index of the system icon associated with the specified drive. Returns -1 if the image list has not been assigned.</returns>    
    Function GetBitmapDriver(const aDrive: String):Integer;
    
    /// <summary>
    /// Builds items for a TcxImageComboBox component with CDs optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>    
    procedure BuildItemCD(aItemsCxComboBox:TcximageComboBoxItems);
    
    /// <summary>
    /// Builds items for a TcxImageComboBox component with CDs double layer optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>    
    procedure BuildItemCD_DL(aItemsCxComboBox: TcximageComboBoxItems);

    /// <summary>
    /// Builds items for a TcxImageComboBox component with DVSs optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>        
    procedure BuildItemDVD(aItemsCxComboBox:TcximageComboBoxItems);
    
    /// <summary>
    /// Builds items for a TcxImageComboBox component with Blu-ray optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>        
    procedure BuildItemBDR(aItemsCxComboBox:TcximageComboBoxItems);

    /// <summary>
    /// Builds items for a TcxImageComboBox component with DVDs double layer optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>        
    procedure BuildItemDVD_DL(aItemsCxComboBox: TcximageComboBoxItems);

    /// <summary>
    /// Builds items for a TcxImageComboBox component with all optical drive.
    /// </summary>
    /// <param name="aItemsCxComboBox">The TcxImageComboBoxItems component to populate with items.</param>        
    procedure BuilcxComboBoxAll(aItemsCxComboBox: TcximageComboBoxItems);
    
    {Property}    
    /// <summary>
    /// Property indicating whether the device can burn CDs.
    /// </summary>
    /// <remarks>
    /// The property is read-only and returns a boolean value.
    /// </remarks>
    Property CanBurnCD      : Boolean         read GetCanBurnCD;
    
    /// <summary>
    /// Property indicating whether the device can burn CDs double layer.
    /// </summary>
    /// <remarks>
    /// The property is read-only and returns a boolean value.
    /// </remarks>
    Property CanBurnCD_DL   : Boolean         read GetCanBurnCD_DL;
    
    /// <summary>
    /// Property indicating whether the device can burn DVDs.
    /// </summary>
    /// <remarks>
    /// The property is read-only and returns a boolean value.
    /// </remarks>    
    Property CanBurnDVD     : Boolean         read GetCanBurnDVD;

    /// <summary>
    /// Property indicating whether the device can burn DVDs double layer.
    /// </summary>
    /// <remarks>
    /// The property is read-only and returns a boolean value.
    /// </remarks>       
    Property CanBurnDVD_DL  : Boolean         read GetCanBurnDVD_DL;

    /// <summary>
    /// Property indicating whether the device can burn Blu-ray disk.
    /// </summary>
    /// <remarks>
    /// The property is read-only and returns a boolean value.
    /// </remarks>       
    Property CanBurnBDR     : Boolean         read GetCanBurnDBR;
    
    ///<summary>
    /// Property that returns True if the system can burn discs, False otherwise.
    ///</summary>    
    property SystemCanBurn  : Boolean         read GetSystemCanBurn;

    ///<summary>
    /// Property that returns the image list containing the small system icons for drives.
    ///</summary>
    property ImageListDriver: TImageList      read FimgListSysSmall;
    
    ///<summary>
    /// Property that determines whether the CD will be automatically erased before burning a new image.
    ///</summary>    
    property EraseCDAuto    : Boolean         read FEraseCDAuto       write FEraseCDAuto;

    ///<summary>
    /// Property that determines whether the CD can be erased.
    ///</summary>    
    property CanErase       : Boolean         read FCanErase          write FCanErase;    
    
    {Events}
    /// <summary>
    /// Event that is fired to report the progress of the burning operation.
    /// </summary> 
    property OnProgressBurn : TOnProgressBurn read FOnProgressBurn    Write FOnProgressBurn;
    
    /// <summary>
    /// Event that is fired to report the logs of the burning operation.
    /// </summary>
    property OnLog          : TonLog          read FOnLog             write FOnLog;
  end;

implementation


{ BurningTool }

Procedure TBurningTool.WriteLog(Const aFunctionName,aDescriptionName:String;Level:TpLivLog;IsDebug:Boolean=False);
begin
  if Assigned(FOnLog) then  
    FOnLog(aFunctionName,aDescriptionName,Level,IsDebug);
end;

function TBurningTool.CreateIsoImage(const aFolderToAdd: String;aVolumeName:String;Const aResultFile:String;aIMAPIDisc:IMAPI_MEDIA_PHYSICAL_TYPE): Boolean;
var LFSI           : TMsftFileSystemImage;
    LDir           : IFsiDirectoryItem;
    LisoFileInt    : IFileSystemImageResult;
    LIStreamValue  : IStream;
    LOleStream     : TOleStream;
    LFileStream    : TFileStream;
begin
  Result := False;
  Try
    LFSI    := TMsftFileSystemImage.Create(nil);
    Try
      LDir := LFSI.Root;
      LFSI.ChooseImageDefaultsForMediaType(aIMAPIDisc);
      LFSI.FileSystemsToCreate := FsiFileSystemUDF;
      LFSI.VolumeName          := aVolumeName;

      {Add the directory and its contents to the file system}
      LDir.AddTree(aFolderToAdd,False);

      {Create an image from the file system}
      LisoFileInt   := LFSI.CreateResultImage();
      LIStreamValue := IStream(LisoFileInt.ImageStream);
      LOleStream    := TOleStream.Create(LIStreamValue);
      try
        LFileStream := TFileStream.Create(aResultFile, fmCreate);
        try
          LOleStream.Position:= 0;
          LFileStream.CopyFrom(LOleStream, LOleStream.Size);
          Result := True;
        finally
          LFileStream.Free;
        end;
      finally
        LOleStream.Free;
      end;
    Finally
      LFSI.Free;
    End;
  Except on E : Exception do
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.CreateIsoImage',E.Message,tplivException);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  End;
end;

Procedure TBurningTool.CancelBurning;
begin
  FAbort := True;
  DoOnProgressBurnCustom(Burning_Aboring);
  if FWriting and Assigned(FCurrentWriter) then
    CancelWriting
  else
  begin
    if not FCancelWriting then
    begin
      if Assigned(FOnProgressBurn) then
        FOnProgressBurn(self,'',0,True,True,0,True);
    end
    else
      {$REGION 'Log'}
      {TSI:IGNORE ON}
        WriteLog('BurningTool.CancelBurning','Not call cancel writing wait end',tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
  end;
end;

procedure TBurningTool.BuildItemCD_DL(aItemsCxComboBox: TcximageComboBoxItems);
begin
  BuilcxComboBox(aItemsCxComboBox,FListaDriveCD_DL);
end;

procedure TBurningTool.BuildItemBDR(aItemsCxComboBox: TcximageComboBoxItems);
begin
  BuilcxComboBox(aItemsCxComboBox,FListaDriveBDR);
end;

procedure TBurningTool.BuildItemCD(aItemsCxComboBox: TcximageComboBoxItems);
begin
  BuilcxComboBox(aItemsCxComboBox,FListaDriveCD)
end;

procedure TBurningTool.BuildItemDVD(aItemsCxComboBox: TcximageComboBoxItems);
begin
  BuilcxComboBox(aItemsCxComboBox,FListaDriveDVD)
end;

procedure TBurningTool.BuildItemDVD_DL(aItemsCxComboBox: TcximageComboBoxItems);
begin
  BuilcxComboBox(aItemsCxComboBox,FListaDriveDVD_DL)
end;

Procedure TBurningTool.BuilcxComboBox(aItemsCxComboBox: TcximageComboBoxItems;aDriverList:TStringList);
var I                      : Integer;
    LCurrentItemCxComboBox : TcxImageComboBoxItem;
begin
  aItemsCxComboBox.BeginUpdate;
  Try
    aItemsCxComboBox.Clear;

    for I := 0 to aDriverList.Count -1 do
    begin
      LCurrentItemCxComboBox             := aItemsCxComboBox.Add;
      LCurrentItemCxComboBox.ImageIndex  := GetBitmapDriver(aDriverList.Strings[I]);
      LCurrentItemCxComboBox.Description := aDriverList.Strings[I];
      LCurrentItemCxComboBox.Value       := Integer(aDriverList.Objects[I])
    end;
  Finally
    aItemsCxComboBox.EndUpdate;
  End;
end;


Procedure TBurningTool.BuilcxComboBoxAll(aItemsCxComboBox: TcximageComboBoxItems);
var I                      : Integer;
    LCurrentItemCxComboBox : TcxImageComboBoxItem;
begin
  aItemsCxComboBox.BeginUpdate;
  Try
    aItemsCxComboBox.Clear;

    for I := 0 to FListaDriveCD.Count -1 do
    begin
      if FListaDriveDVD.IndexOf(FListaDriveCD.Strings[I]) <> -1 then continue;
      if FListaDriveBDR.IndexOf(FListaDriveCD.Strings[I]) <> -1 then continue;
      LCurrentItemCxComboBox             := aItemsCxComboBox.Add;
      LCurrentItemCxComboBox.ImageIndex  := GetBitmapDriver(FListaDriveCD.Strings[I]);
      LCurrentItemCxComboBox.Description := FListaDriveCD.Strings[I];
      LCurrentItemCxComboBox.Tag         := TIPO_SUPPORT_CD;
      LCurrentItemCxComboBox.Value       := Integer(FListaDriveCD.Objects[I])
    end;

    for I := 0 to FListaDriveDVD.Count -1 do
    begin
      if FListaDriveBDR.IndexOf(FListaDriveDVD.Strings[I]) <> -1 then continue;    
      LCurrentItemCxComboBox             := aItemsCxComboBox.Add;
      LCurrentItemCxComboBox.ImageIndex  := GetBitmapDriver(FListaDriveDVD.Strings[I]);
      LCurrentItemCxComboBox.Description := FListaDriveDVD.Strings[I];
      LCurrentItemCxComboBox.Tag         := TIPO_SUPPORT_DVD;
      LCurrentItemCxComboBox.Value       := Integer(FListaDriveDVD.Objects[I])
    end;

    for I := 0 to FListaDriveBDR.Count -1 do
    begin
      LCurrentItemCxComboBox             := aItemsCxComboBox.Add;
      LCurrentItemCxComboBox.ImageIndex  := GetBitmapDriver(FListaDriveBDR.Strings[I]);
      LCurrentItemCxComboBox.Description := FListaDriveBDR.Strings[I];
      LCurrentItemCxComboBox.Tag         := TIPO_SUPPORT_BDR;
      LCurrentItemCxComboBox.Value       := Integer(FListaDriveBDR.Objects[I])
    end;    
    
    
  Finally
    aItemsCxComboBox.EndUpdate;
  End;
end;

Function TBurningTool.IsDriverRW(aDriveIndex : Integer;aSupportType:Integer):Boolean;
var I          : LongInt;
    LvTmp      : Variant;
    LLBound    : LongInt;
    LHBound    : LongInt;
begin
  Result := False;
  if not CheckAssignedAndActivationDrive(aDriveIndex) then Exit;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
    WriteLog('BurningTool.IsDriverRW','Start function',tpLivInfo,True);
  {TSI:IGNORE OFF}
  {$ENDREGION}

  Try
    SafeArrayGetLBound(FDiscRecord.SupportedProfiles, 1, LLBound);
    SafeArrayGetUBound(FDiscRecord.SupportedProfiles, 1, LHBound);

    for I := LLBound to LHBound do
    begin
      SafeArrayGetElement(FDiscRecord.SupportedProfiles, I, LvTmp);

      if VarIsNull(LvTmp) then Continue;

      case LvTmp of
        IMAPI_PROFILE_TYPE_CD_REWRITABLE               :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('BurningTool.IsDriverRW',' Supported Profiles IMAPI_PROFILE_TYPE_CD_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo,True);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            Result := aSupportType = TIPO_SUPPORT_CD;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_DASH_REWRITABLE        :   begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsDriverRW',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_DASH_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo,True);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            Result := aSupportType = TIPO_SUPPORT_DVD;
                                                          end;

        IMAPI_PROFILE_TYPE_DVD_PLUS_RW_DUAL           :   begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsDriverRW',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_PLUS_RW_DUAL '+ VarToStr(LvTmp),tpLivInfo,True);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            Result := aSupportType = TIPO_SUPPORT_DVD_DL;
                                                          end;
        IMAPI_PROFILE_TYPE_BD_REWRITABLE              :   begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsDriverRW',' Supported Profiles IMAPI_PROFILE_TYPE_BD_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo,True);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            Result := aSupportType = TIPO_SUPPORT_BDR;
                                                          end;
      end;

      if Result then Break;
    end;
  Except on E : Exception do
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.IsDriverRW',Format('Exception [%s] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  End;
end;

{Build drivers list}
procedure TBurningTool.BuildListDrivesOfType;
var LDriveMap  : DWORD;
    LdMask     : DWORD;
    LdRoot     : String;
    LI         : Integer;
begin
  if Not Assigned(FDiriverList) then Exit;

  LdRoot     := 'A:\';
  LDriveMap  := GetLogicalDrives;
  LdMask     := 1;

  for LI := 0 to 32 do
  begin
    if (LdMask and LDriveMap) <> 0 then
    begin
      if GetDriveType(PChar(LdRoot)) = DRIVE_CDROM then
      begin
        FDiriverList.Add(LdRoot[1] + ':');
      end;
    end;
    LdMask := LdMask shl 1;
    Inc(LdRoot[1]);
  end;
end;

procedure TBurningTool.IsWrittableDriver(aSupportedProfiles: PSafeArray;Var aWCd,aWDVD,aWBDR,aWDvd_DL,awCD_DL:Boolean);
var LLBound  : LongInt;
    LHBound  : LongInt;
    I       : Integer;
    LvTmp    : Variant;
begin
    SafeArrayGetLBound(aSupportedProfiles, 1, LLBound);
    SafeArrayGetUBound(aSupportedProfiles, 1, LHBound);
    {Rewritable}
    for I := LLBound to LHBound do
    begin
      SafeArrayGetElement(aSupportedProfiles, I, LvTmp);

      if VarIsNull(LvTmp) then Continue;

      case LvTmp of
        {$REGION 'Log'}
        {TSI:IGNORE ON}
        IMAPI_PROFILE_TYPE_NON_REMOVABLE_DISK          : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_NON_REMOVABLE_DISK '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_INVALID                     : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_INVALID '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_REMOVABLE_DISK              : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_REMOVABLE_DISK '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_MO_ERASABLE                 : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_MO_ERASABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_MO_WRITE_ONCE               : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_MO_WRITE_ONCE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_AS_MO                       : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_AS_MO '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_CDROM                       : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_CDROM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_BD_ROM                      : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_BD_ROM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_HD_DVD_ROM                  : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_HD_DVD_ROM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_HD_DVD_RECORDABLE           : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_HD_DVD_RECORDABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_HD_DVD_RAM                  : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_HD_DVD_RAM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_DDCDROM                     : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DDCDROM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_NON_STANDARD                : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_NON_STANDARD '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_DVDROM                      : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVDROM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_DVD_PLUS_R                  : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_PLUS_R '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_PROFILE_TYPE_DVD_RAM                     : WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_RAM '+ VarToStr(LvTmp),tpLivInfo,True);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        IMAPI_PROFILE_TYPE_CD_RECORDABLE               :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_CD_RECORDABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWCd := True;
                                                          end;
        IMAPI_PROFILE_TYPE_CD_REWRITABLE               :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_CD_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWCd := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DDCD_REWRITABLE               :begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DDCD_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            awCD_DL := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DDCD_RECORDABLE               :begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DDCD_RECORDABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            awCD_DL := True;
                                                          end;

        IMAPI_PROFILE_TYPE_DVD_DASH_RECORDABLE         :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_DASH_RECORDABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDVD := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_DASH_REWRITABLE         :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_DASH_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDVD := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_DASH_RW_SEQUENTIAL      :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_DASH_RW_SEQUENTIAL '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDVD := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_PLUS_RW                 :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_PLUS_RW '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDVD := True;
                                                          end;

        IMAPI_PROFILE_TYPE_BD_R_SEQUENTIAL             :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_BD_R_SEQUENTIAL '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWBDR := True;
                                                          end;
        IMAPI_PROFILE_TYPE_BD_R_RANDOM_RECORDING        : begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_BD_R_RANDOM_RECORDING '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWBDR := True;
                                                          end;

        IMAPI_PROFILE_TYPE_BD_REWRITABLE               :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_BD_REWRITABLE '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWBDR := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_PLUS_R_DUAL            :   begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_PLUS_R_DUAL '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDvd_DL := True;
                                                          end;
        IMAPI_PROFILE_TYPE_DVD_PLUS_RW_DUAL            :  begin
                                                            {$REGION 'Log'}
                                                            {TSI:IGNORE ON}
                                                              WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles IMAPI_PROFILE_TYPE_DVD_PLUS_RW_DUAL '+ VarToStr(LvTmp),tpLivInfo);
                                                            {TSI:IGNORE OFF}
                                                            {$ENDREGION}
                                                            aWDvd_DL := True;
                                                          end;
      else
        {$REGION 'Log'}
        {TSI:IGNORE ON}
          WriteLog('TBurningTool.IsWrittableDriver',' Supported Profiles unknown '+ VarToStr(LvTmp),tpLivWarning);
        {TSI:IGNORE OFF}
        {$ENDREGION}
      end;
    end;
end;

procedure TBurningTool.IsRecordableDriver(aSupportedFeaturePages: PSafeArray;Var aWCd,aWDVD,aWBDR,aWDvd_DL,awCD_DL:Boolean);
var LLBound : LongInt;
    LHBound : LongInt;
    I       : Integer;
    LvTmp   : Variant;
begin
    SafeArrayGetLBound(aSupportedFeaturePages, 1, LLBound);
    SafeArrayGetUBound(aSupportedFeaturePages, 1, LHBound);

    for I := LLBound to LHBound do
    begin
      SafeArrayGetElement(aSupportedFeaturePages, I, LvTmp);

      if VarIsNull(LvTmp) then Continue;

      case LvTmp of
        {$REGION 'Log'}
        {TSI:IGNORE ON}
        IMAPI_FEATURE_PAGE_TYPE_PROFILE_LIST                   : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_PROFILE_LIST '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_CORE                           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CORE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_MORPHING                       : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_MORPHING '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_REMOVABLE_MEDIUM               : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_REMOVABLE_MEDIUM '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_WRITE_PROTECT                  : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_WRITE_PROTECT '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_RANDOMLY_READABLE              : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_RANDOMLY_READABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_CD_MULTIREAD                   : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_MULTIREAD '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_CD_READ                        : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_READ '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_DVD_READ                       : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_READ '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_RANDOMLY_WRITABLE              : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_RANDOMLY_WRITABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_INCREMENTAL_STREAMING_WRITABLE : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_INCREMENTAL_STREAMING_WRITABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_SECTOR_ERASABLE                : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_SECTOR_ERASABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_FORMATTABLE                    : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_FORMATTABLE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_HARDWARE_DEFECT_MANAGEMENT     : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_HARDWARE_DEFECT_MANAGEMENT '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_WRITE_ONCE                     : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_WRITE_ONCE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_RESTRICTED_OVERWRITE           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_RESTRICTED_OVERWRITE '+ VarToStr(LvTmp),tpLivInfo,True);
        {This value has been deprecated}
        IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_READ         : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_READ '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_MRW                            : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_MRW '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_ENHANCED_DEFECT_REPORTING      : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_ENHANCED_DEFECT_REPORTING '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_R                     : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_R '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_RIGID_RESTRICTED_OVERWRITE     : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_RIGID_RESTRICTED_OVERWRITE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_HD_DVD_READ                    : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_HD_DVD_READ '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_HD_DVD_WRITE                   : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_HD_DVD_WRITE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_POWER_MANAGEMENT               : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_POWER_MANAGEMENT '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_SMART                          : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_SMART '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_EMBEDDED_CHANGER               : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_EMBEDDED_CHANGER '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_CD_ANALOG_PLAY                 : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_ANALOG_PLAY '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_MICROCODE_UPDATE               : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_MICROCODE_UPDATE '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_TIMEOUT                        : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_TIMEOUT '+ VarToStr(LvTmp),tpLivInfo,True);
        IMAPI_FEATURE_PAGE_TYPE_DVD_CSS                        : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_CSS '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_REAL_TIME_STREAMING            : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_REAL_TIME_STREAMING '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_LOGICAL_UNIT_SERIAL_NUMBER     : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_LOGICAL_UNIT_SERIAL_NUMBER '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_MEDIA_SERIAL_NUMBER            : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_MEDIA_SERIAL_NUMBER '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_DISC_CONTROL_BLOCKS            : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DISC_CONTROL_BLOCKS '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_DVD_CPRM                       : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_CPRM '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_FIRMWARE_INFORMATION           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_FIRMWARE_INFORMATION '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_AACS                           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_AACS '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_VCPS                           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_VCPS '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_BD_PSEUDO_OVERWRITE            : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_BD_PSEUDO_OVERWRITE '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_BD_READ                        : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_BD_READ '+ VarToStr(LvTmp),tpLivInfo);
        IMAPI_FEATURE_PAGE_TYPE_LAYER_JUMP_RECORDING           : WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_LAYER_JUMP_RECORDING '+ VarToStr(LvTmp),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        IMAPI_FEATURE_PAGE_TYPE_CDRW_CAV_WRITE                 : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CDRW_CAV_WRITE '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWCd := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_CD_TRACK_AT_ONCE               : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_TRACK_AT_ONCE '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWCd := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_CD_MASTERING                   : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_MASTERING '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWCd := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_CD_RW_MEDIA_WRITE_SUPPORT      : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_CD_RW_MEDIA_WRITE_SUPPORT '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWCd := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_R_WRITE :      begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_R_WRITE '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    awCD_DL := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_RW_WRITE :     begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DOUBLE_DENSITY_CD_RW_WRITE '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    awCD_DL := True;
                                                                 end;

        IMAPI_FEATURE_PAGE_TYPE_DVD_DASH_WRITE                 : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_DASH_WRITE '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWDVD := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_RW                    : begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_RW '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWDVD := True;
                                                                 end;
        IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_R_DUAL_LAYER :          begin
                                                                    {$REGION 'Log'}
                                                                    {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_DVD_PLUS_R_DUAL_LAYER '+ VarToStr(LvTmp),tpLivInfo);
                                                                    {TSI:IGNORE OFF}
                                                                    {$ENDREGION}
                                                                    aWDvd_DL := True;
                                                                 end;

        IMAPI_FEATURE_PAGE_TYPE_BD_WRITE                       : begin
                                                                   {$REGION 'Log'}
                                                                   {TSI:IGNORE ON}
                                                                      WriteLog('TBurningTool.IsRecordableDriver',' Feature pages IMAPI_FEATURE_PAGE_TYPE_BD_WRITE '+ VarToStr(LvTmp),tpLivInfo);
                                                                   {TSI:IGNORE OFF}
                                                                   {$ENDREGION}
                                                                   aWBDR := True;
                                                                 end;
      else
        {$REGION 'Log'}
        {TSI:IGNORE ON}
          WriteLog('TBurningTool.IsRecordableDriver',' Feature pages unknown '+ VarToStr(LvTmp),tpLivWarning);
        {TSI:IGNORE OFF}
        {$ENDREGION}
      end;
    end;
end;

{Get ImageList by Windows image }
procedure TBurningTool.CreateImageListIconSystem;
var LInfo : TSHFileInfo;
begin
  FimgListSysSmall              := TImageList.Create(nil);
  FimgListSysSmall.DrawingStyle := dsTransparent;
  FimgListSysSmall.Handle       := SHGetFileInfo('', 0, LInfo, SizeOf(TSHFileInfo),  SHGFI_SMALLICON or SHGFI_SYSICONINDEX or SHGFI_PIDL );
  FimgListSysSmall.ShareImages  := True;
end;

{Init driver lists}
procedure TBurningTool.CreateInterListDriveByType;
begin
  FListaDriveCD           := TStringList.Create;
  FListaDriveCD_DL        := TStringList.Create;
  FListaDriveDVD          := TStringList.Create;
  FListaDriveDVD_DL       := TStringList.Create;
  FListaDriveBDR          := TStringList.Create;
  FDiriverList            := TStringList.Create;
end;

constructor TBurningTool.Create;
begin
  { Create a DiscMaster2 object to connect to CD/DVD drives.}
  FDiscMaster             := TMsftDiscMaster2.Create(nil);
  FDiscMaster.AutoConnect := False;
  FDiscMaster.ConnectKind := ckRunningOrNew;
  {Create a DiscRecorder object for the specified burning device}
  FDiscRecord             := TMsftDiscRecorder2.Create(nil);
  FDiscRecord.AutoConnect := False;
  FDiscRecord.ConnectKind := ckRunningOrNew;
  CreateInterListDriveByType;
  BuildListDrivesOfType;
  CreateImageListIconSystem;
  {Indica se sul sistama ci sono Masterizzatori}
  if Not FDiscMaster.IsSupportedEnvironment then
  begin
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.Create',Format('IsSupportedEnvironment [ False ] PC without a writing drive',[]),tpLivWarning);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    Exit;
  end;
  SearchRecordableDriver;
end;

Procedure TBurningTool.SearchRecordableDriver;
var LIdxDriver    : Integer;
    LWDvd         : Boolean;
    LWDvd_DL      : Boolean;
    LWCd          : Boolean;
    LWBDR         : Boolean;
    LwCD_DL       : Boolean;
begin
  {Controllo tutti i masterizzatori per sapere quali supporti sono abilitato a masterizzare}
  For LIdxDriver := 0 to FDiscMaster.Count - 1 do
  begin
    if not CheckAssignedAndActivationDrive(LIdxDriver) then Continue;
    Try
      Try
        {$REGION 'Log'}
        {TSI:IGNORE ON}
          { *** - Formatting to display recorder info}
          WriteLog('TBurningTool.SearchRecordableDriver',' "--------------------------------------------------------------------------------"',tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver','" ActiveRecorderId: " '+ FDiscRecord.ActiveDiscRecorder,tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver','"        Vendor Id: " '+ FDiscRecord.VendorId,tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver','"       Product Id: " '+ FDiscRecord.ProductId,tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver','" Product Revision: " '+ FDiscRecord.ProductRevision,tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver','"       VolumeName: " '+ FDiscRecord.VolumeName,tpLivInfo);
          Try
            WriteLog('TBurningTool.SearchRecordableDriver','"   Can Load Media: " '+ BoolToStr(FDiscRecord.DeviceCanLoadMedia,True),tpLivInfo);
          Except on E : Exception do
            begin
              {$REGION 'Log'}
              {TSI:IGNORE ON}
                 WriteLog('TBurningTool.SearchRecordableDriver',Format('Can not print load media value last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tpLivWarning);
              {TSI:IGNORE OFF}
              {$ENDREGION}
            end;
          End;
          WriteLog('TBurningTool.SearchRecordableDriver','"    Device Number: " '+ IntToStr(FDiscRecord.LegacyDeviceNumber),tpLivInfo);
          WriteLog('TBurningTool.SearchRecordableDriver',' "--------------------------------------------------------------------------------"',tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        LWDvd    := False;
        LWCd     := False;
        LWBDR    := False;
        LWDvd_DL := False;
        LwCD_DL  := False;
        {Verifico se il disco � recordable}
        isRecordableDriver(FDiscRecord.SupportedFeaturePages,LWCd,LWDvd,LWBDR,LWDvd_DL,LwCD_DL);
        {Verifico se il disco � un masterizzatore rescrivibile}
        IsWrittableDriver(FDiscRecord.SupportedProfiles,LWCd,LWDvd,LWBDR,LWDvd_DL,LwCD_DL);
        {Aggiungo il disco alla corretta lista interna di driver}
        BuildListDriverType(FDiscRecord.VolumeName,LWCd,LWDvd,LWBDR,LWDvd_DL,LwCD_DL,LIdxDriver);
      Finally
        FDiscRecord.Disconnect;
      End;
    Except on E : Exception do
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.SearchRecordableDriver',Format('Exception [%s] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    End;
  end;
end;

Procedure TBurningTool.BuildListDriverType(aVolumeName:WideString;aWcd,aWdvd,aWbdr,aWdvdDl,awCD_DL:Boolean;aIdx:Integer);
var I             : integer;
    LBuffer       : array [0 .. 49] of Char;
    LsLabelDriver : String;
begin
  for I := 0 to FDiriverList.Count -1 do
  begin
    if GetVolumeNameForVolumeMountPoint(PWideChar(FDiriverList.Strings[I]+'\'), LBuffer, Length(LBuffer)) then
    begin
      if LBuffer = aVolumeName then
      begin
        LsLabelDriver := GetDriveTypeLabel(FDiriverList.Strings[I]);

        if LsLabelDriver.IsEmpty then
          LsLabelDriver := FDiriverList.Strings[I];

        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.BuildListDriverType',Format('Mount point for drive [ %s\ ] with label [ %s ] is [%s]',[FDiriverList.Strings[I],LsLabelDriver,aVolumeName]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        if aWcd  then
          FListaDriveCD.AddObject(LsLabelDriver,TObject(aIdx));

        if aWdvd then
          FListaDriveDVD.AddObject(LsLabelDriver,TObject(aIdx));

        if aWbdr  then
          FListaDriveBDR.AddObject(LsLabelDriver,TObject(aIdx));

        if aWdvdDl then
          FListaDriveDVD_DL.AddObject(LsLabelDriver,TObject(aIdx));

        if awCD_DL then
          FListaDriveDVD_DL.AddObject(LsLabelDriver,TObject(aIdx));
        Break;
      end;
    end
    else
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.BuildListDriverType',Format('Unable find Mount point for drive with letter [ %s\ ] - Error [%s]',[FDiriverList.Strings[I],SysErrorMessage(GetLastError)]),tplivError);
      {TSI:IGNORE OFF}
      {$ENDREGION}
  end;
end;

function TBurningTool.GetDriveTypeLabel(Const aDriveChar: String): string;
var LInfo              : TSHFileInfo;
    LNotUsed           : DWORD;
    LVolumeFlags       : DWORD;
    LVolumeInfo        : Array[0..MAX_PATH] of char;
    LVolumeSerialNumber: Integer;
    LiPos              : integer;
    LsTmp              : String;
begin
  SHGetFileInfo(PChar(aDriveChar+'\'), 0, LInfo, SizeOf(LInfo), SHGFI_DISPLAYNAME);
  GetVolumeInformation(pChar(aDriveChar + '\'),LVolumeInfo, SizeOf(LVolumeInfo),@LVolumeSerialNumber, LNotUsed, LVolumeFlags, NIL, 0);
  Result := Trim(StringReplace(LInfo.szDisplayName,LVolumeInfo,'',[rfReplaceAll,rfIgnoreCase]));

  LiPos := Pos(':)', Result);
  if LiPos > 0 then
  begin
    LsTmp := Copy(Result, LiPos-2, 4);
    Delete(Result, LiPos-2, MaxInt);
    Result := Format('[%s] %s',[Copy(LsTmp, 2, 2),Result])
  end;
end;

function TBurningTool.GetIndexCDROM(const aLetter: String): Integer;
var LsLetter : String;
begin
  Result   := -1;
  LsLetter := Copy(aLetter,1,2);
  if Pos(':',aLetter) = 0 then
    LsLetter := Format('%s:',[aLetter]);

  Result := FDiriverList.IndexOf(LsLetter);
end;

destructor TBurningTool.Destroy;
begin
  try
    if assigned(FCurrentWriter) then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.Destroy',Format('Current writer is assigned',[]),tplivError);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      FCurrentWriter.Disconnect;
      FCurrentWriter.Free;
    end;
  Except on E : Exception do
    begin
      FCurrentWriter := nil;
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.Destroy',Format('Exception destroy currentWriters [ %s ] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
  if Assigned(FListaDriveCD) then
    FreeAndNil(FListaDriveCD);
  if Assigned(FListaDriveCD_DL) then
    FreeAndNil(FListaDriveCD_DL);
  if Assigned(FListaDriveBDR) then
    FreeAndNil(FListaDriveBDR);
  if Assigned(FListaDriveDVD) then
    FreeAndNil(FListaDriveDVD);
  if Assigned(FListaDriveDVD_DL) then
    FreeAndNil(FListaDriveDVD_DL);
  if Assigned(FDiscMaster) then
    FreeAndNil(FDiscMaster);
  if Assigned(FDiscRecord) then
    FreeAndNil(FDiscRecord);
  if Assigned(FimgListSysSmall) then
    FreeAndNil(FimgListSysSmall);

  inherited;
end;

Function TBurningTool.ActiveDiskRecorder(aIdexDriver: Integer):Boolean;
var LuniqueId : Widestring;
begin
  Result   := false;
  if aIdexDriver > FDiscMaster.Count then Exit;

  LuniqueId := FDiscMaster.Item[aIdexDriver];
  {$REGION 'Log'}
  {TSI:IGNORE ON}
  WriteLog('TBurningTool.ActiveDiskRecorder',Format('UniqueId [ %s ]',[LuniqueId]),tpLivInfo,True);
  {TSI:IGNORE OFF}
  {$ENDREGION}

  FDiscRecord.Disconnect;
  FDiscRecord.ConnectKind := ckRunningOrNew;
  Try
    FDiscRecord.InitializeDiscRecorder(LuniqueId);
    FLastuniqueId := LuniqueId;
    Result        := True;
  Except on E : Exception do
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.ActiveDiskRecorder',Format('UniqueId [ %s ] - Exception [ %s ] last error [ %s ]',[LuniqueId,e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      FLastuniqueId := String.Empty;
    end;
  End;
end;

{Chiude il cassetto del drive }
Function TBurningTool.CloseTray(aIdexDriver: Integer):Boolean;
begin
  Result := False;
  if not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;

  Try
    if Not FDiscRecord.DeviceCanLoadMedia then
    begin
      Result := ( MessageBox(0, Pchar(Media_eject_Not_Supported), PChar(Application.Title),
                       MB_ICONINFORMATION or MB_OK or MB_YESNO or MB_TOPMOST ) in [IDYES] );
      FAbort := not Result;
      Exit;
    end;
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.CloseTray',Format('Close tray ',[]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    FDiscRecord.CloseTray;
  Except On E:Exception do
    begin
      if Not ( MessageBox(0, Pchar(Unknow_status_eject), PChar(Application.Title),
                       MB_ICONINFORMATION or MB_OK or MB_YESNO or MB_TOPMOST ) in [IDYES] )
      then
      begin
        FAbort := True;
        Exit;
      end;
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.CloseTray',Format('Exception %s last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
  Result := True;
end;

{ Apre il cassetto del drive }
Function TBurningTool.DriveEject(aIdexDriver: Integer):Boolean;
begin
  Result := False;
  if not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.DriverEject',Format('Eject Media ',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  Try
    if Not FDiscRecord.DeviceCanLoadMedia then
    begin
      Result := ( MessageBox(0, Pchar(Media_eject_Not_Supported_2), PChar(Application.Title),
                       MB_ICONINFORMATION or MB_OK or MB_YESNO or MB_TOPMOST ) in [IDYES] );
      FAbort := not Result;
      Exit;
    end;

    FDiscRecord.EjectMedia;
    Result := True;
  Except On E:Exception do
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.DriverEject',Format('Exception %s last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
end;

function TBurningTool.SetBurnVerification(var aDataWriter : TMsftDiscFormat2Data;aVerificationLevel:IMAPI_BURN_VERIFICATION_LEVEL):Boolean;
var LBurnVerification : IBurnVerification;
    LResultQI         : Integer;
    LHresult         : HRESULT;
begin
  {
    IMAPI_BURN_VERIFICATION_LEVEL  Verifica del disco
      MsftDiscFormat2Data
      None                --> No burn verification.
      Quick Verification  --> READ_DISC_INFO command works and data appears correct READ_TRACK_INFO command works on all tracks
                              Checksum comparison of a small set of disc sectors to stream bits
      Full Verification --> Performs the same heuristic checks as the 'Quick' method, but will also read the entire last session and compare a checksum to the burned stream.
  }

  Result := False;
  if Not Assigned(aDataWriter) then Exit;

  Try
    LBurnVerification := nil;
    LResultQI         := aDataWriter.DefaultInterface.QueryInterface(IBurnVerification,LBurnVerification);

    if LResultQI = S_OK then
    begin
      LHresult := LBurnVerification.Set_BurnVerificationLevel(aVerificationLevel);
      Result   := LHresult = S_OK;
      if Not Result then
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.SetBurnVerification',Format('Error %d last error [ %s ]',[LResultQI,SysErrorMessage(GetLastError)]),tplivError);
        {TSI:IGNORE OFF}
        {$ENDREGION}
    end
    else
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.SetBurnVerification',Format('Error %d last error [ %s ]',[LResultQI,SysErrorMessage(GetLastError)]),tplivError);
      {TSI:IGNORE OFF}
      {$ENDREGION}
  except on E:Exception do
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.SetBurnVerification',Format('Exception %s last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
End;

{Elimina il contenuto del disco riscrivibile}
Function TBurningTool.EraseDisk(aIdexDriver,aSupportType:Integer;aEject:Boolean):Boolean;
Var LDiskFormat : TMsftDiscFormat2Erase;
    LErrorMedia : Boolean;
    LisSupportRW: Boolean;
    LDataWriter : TMsftDiscFormat2Data;
begin
  Result := False;

  if not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.EraseDisk',Format('Start Erase disk ',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  Try
    LDataWriter            := TMsftDiscFormat2Data.Create(nil);
    LDataWriter.AutoConnect:= False;
    LDataWriter.ConnectKind:= ckRunningOrNew;
    LDataWriter.Recorder   := FDiscRecord.DefaultInterface;
    LDataWriter.ClientName := ExtractFileName(Application.ExeName);
    if not SetBurnVerification(LDataWriter,IMAPI_BURN_VERIFICATION_QUICK) then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.EraseDisk',Format('Unable set check disk erase',[]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;

    Try
      {Verifico se nell'unit� � presente almeno un disco altrimenti lo richiedo}
      if DiskIsPresentOnDrive(aIdexDriver,LDataWriter) then
      begin
        {Verifico se nell'unita c'� un disco idoneo al supporto}
        if CheckMediaBySupport(aIdexDriver,aSupportType,LisSupportRW,LDataWriter) then
        begin
          {Verifico se nell'unitca c'� un disco vuoto}
          if Not isDiskEmpty(LDataWriter,aIdexDriver,LErrorMedia) then
          begin
            {verifico se nell'unit� c'� un dico rescrivibile}
            if LisSupportRW then
            begin
              if Not isDiskWritable(LDataWriter,aIdexDriver,LErrorMedia) then
              begin
                {$REGION 'Log'}
                {TSI:IGNORE ON}
                   WriteLog('TBurningTool.EraseDisk',Format('Disk on drive is not rewritable',[]),tplivError);
                {TSI:IGNORE OFF}
                {$ENDREGION}
                Exit;
              end;
            end
            else
            begin
              {$REGION 'Log'}
              {TSI:IGNORE ON}
                 WriteLog('TBurningTool.EraseDisk',Format('Disk type on drive is not supported for erase ',[]),tplivError);
              {TSI:IGNORE OFF}
              {$ENDREGION}
              Exit;
            end;
          end
          else
          begin
            {il disco � vuoto non ha senzo fare una formattazione}
            Result := True;
            Exit;
          end;
        end
        else
          {$REGION 'Log'}
          {TSI:IGNORE ON}
             WriteLog('TBurningTool.EraseDisk',Format('Disk type on drive is not supported for erase [Different type] ',[]),tplivError);
          {TSI:IGNORE OFF}
          {$ENDREGION}
      end
      else
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.EraseDisk',Format('No Disk on drive',[]),tplivError);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        Exit;
      end;
    Finally
      LDataWriter.Disconnect;
      LDataWriter.Free;
    End;

    LDiskFormat := TMsftDiscFormat2Erase.Create(nil);
    Try
      LDiskFormat.AutoConnect:= False;
      LDiskFormat.ConnectKind:= ckRunningOrNew;

      LDiskFormat.Recorder   := FDiscRecord.DefaultInterface;
      LDiskFormat.ClientName := ExtractFileName(Application.ExeName);
      Try
        LDiskFormat.FullErase  := True;
        LDiskFormat.OnUpdate   := MsftEraseDataUpdate;
        DoOnProgressBurnCustom(Disk_Erase);
        LDiskFormat.EraseMedia;
        DoOnProgressBurnCustom(Disk_Erase_compleate);
        Result := True;
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.EraseDisk','Erase disk compleate',tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        if aEject then
          FDiscRecord.EjectMedia;
      Except on E : Exception do
        begin
          {$REGION 'Log'}
          {TSI:IGNORE ON}
             WriteLog('TBurningTool.EraseDisk',Format('Exception erase [%s] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
          {TSI:IGNORE OFF}
          {$ENDREGION}
        end;
      End;
    Finally
      LDiskFormat.Disconnect;
      LDiskFormat.Free;
    End;
  Except on E : Exception do
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.EraseDisk',Format('Generic [%s] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
end;

Function TBurningTool.IntFRecordAssigned:Boolean;
begin
  Result := Assigned(FDiscRecord);
  if Not Result  then
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.IntFRecordAssigned',Format('Interface of disk recorder not assigned ',[]),tplivError);
    {TSI:IGNORE OFF}
    {$ENDREGION}
end;

Function TBurningTool.IntFDiskMasterAssigned:Boolean;
begin
  Result := Assigned(FDiscMaster);
  if Not Result  then
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.IntFDiskMasterAssigned',Format('Interface of disk master not assigned ',[]),tplivError);
    {TSI:IGNORE OFF}
    {$ENDREGION}
end;

Function TBurningTool.IntFWriterAssigned(var aDataWriter:TMsftDiscFormat2Data):Boolean;
begin
  Result := Assigned(aDataWriter);
  if Not Result  then
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.IntFWriterAssigned',Format('Interface of disk writer not assigned ',[]),tplivError);
    {TSI:IGNORE OFF}
    {$ENDREGION}
end;

Function TBurningTool.FoundLetterDrive(aIndex:Integer;Var aLetterDrive : String):Boolean;

  procedure SearchOnList(aListaDrive:TStringList);
  var I : Integer;
  begin
    for I := 0 to aListaDrive.Count -1 do
    begin
      if Integer(aListaDrive.Objects[I]) = aIndex then
      begin
        Result       := True;
        aLetterDrive := aListaDrive.Strings[I];
        Break;
      end;
    end;
  end;

begin
  Result       := False;
  aLetterDrive := '';

  SearchOnList(FListaDriveCD);

  if not Result then
    SearchOnList(FListaDriveCD_DL);

  if not Result then
    SearchOnList(FListaDriveDVD);

  if not Result then
    SearchOnList(FListaDriveDVD_DL);

  if not Result then
    SearchOnList(FListaDriveBDR);

  if Not Result then
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.FoundLetterDrive',Format('Not found letter drive for idex [ %d ]',[aIndex]),tplivError)
    {TSI:IGNORE OFF}
    {$ENDREGION}
  else
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.FoundLetterDrive',Format('Drive letter [ %s ]',[aLetterDrive]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
end;

Function TBurningTool.DiskIsPresentOnDrive(aIdexDriver:Integer;var aDataWriter:TMsftDiscFormat2Data):Boolean;
begin
  Result := False;
  if Not IntFWriterAssigned(aDataWriter) then exit;
  if Not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;
  Try
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.DiskIsPresentOnDrive',Format('Check if disk is present on drive',[]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    Result := aDataWriter.CurrentPhysicalMediaType <> IMAPI_MEDIA_TYPE_UNKNOWN;
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.DiskIsPresentOnDrive',Format('disk is present [ %s ]',[BoolToStr(Result,True)]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  Except on E: Exception do
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.DiskIsPresentOnDrive',Format('Error [ %s ]',[E.Message]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  End;
end;

function TBurningTool.CheckAssignedAndActivationDrive(IndexDriver:Integer):Boolean;
begin
  Result := False;

  if Not IntFRecordAssigned or
     Not IntFDiskMasterAssigned or
     Not ActiveDiskRecorder(IndexDriver) then Exit;

  Result := True;
end;

Function TBurningTool.CheckMediaBySupport(aIdexDriver:integer;aSupportType:integer;var aIsRW:Boolean;var aDataWriter:TMsftDiscFormat2Data) : Boolean;
begin
  Result := False;
  if Not IntFWriterAssigned(aDataWriter) then exit;
  if Not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.CheckMediaBySupport',Format('Check disk type ',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  aIsRW := False;

  Try
    case aDataWriter.CurrentPhysicalMediaType of
      IMAPI_MEDIA_TYPE_UNKNOWN              : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type not present or unknown',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_CDROM                : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_CDROM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_DISK                 : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DISK',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_HDDVDROM             : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_HDDVDROM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_HDDVDR               : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_HDDVDR',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_HDDVDRAM             : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                 WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_HDDVDRAM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_BDROM                : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_BDROM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_CDR                  : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_CDR',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType = TIPO_SUPPORT_CD;
                                              end;
      IMAPI_MEDIA_TYPE_CDRW                 : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_CDRW',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType = TIPO_SUPPORT_CD;
                                                aIsRW   := True;
                                              end;
      IMAPI_MEDIA_TYPE_DVDROM               : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDROM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_DVDRAM               : {$REGION 'Log'}
                                              {TSI:IGNORE ON}
                                                WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDRAM',tpLivInfo,True);
                                              {TSI:IGNORE OFF}
                                              {$ENDREGION}
      IMAPI_MEDIA_TYPE_DVDPLUSR             : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDPLUSR',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                              end;
      IMAPI_MEDIA_TYPE_DVDPLUSRW            : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDPLUSRW',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                                aIsRW   := True;
                                              end;
      IMAPI_MEDIA_TYPE_DVDPLUSR_DUALLAYER   : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDPLUSR_DUALLAYER',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD_DL,TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                              end;
      IMAPI_MEDIA_TYPE_DVDDASHR_DUALLAYER	  : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDDASHR_DUALLAYER',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD_DL,TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                              end;
      IMAPI_MEDIA_TYPE_DVDDASHR             : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDDASHR',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                              end;
      IMAPI_MEDIA_TYPE_DVDDASHRW 			      : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDDASHRW',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                                aIsRW   := True;
                                              end;
      IMAPI_MEDIA_TYPE_DVDPLUSRW_DUALLAYER  : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_DVDPLUSRW_DUALLAYER',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_DVD_DL,TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                                aIsRW   := True;
                                              end;
      IMAPI_MEDIA_TYPE_BDR                  : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_BDR',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_BDR,TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                              end;
      IMAPI_MEDIA_TYPE_BDRE                 : begin
                                                {$REGION 'Log'}
                                                {TSI:IGNORE ON}
                                                  WriteLog('TBurningTool.CheckMediaBySupport',' Support type IMAPI_MEDIA_TYPE_BDRE',tpLivInfo);
                                                {TSI:IGNORE OFF}
                                                {$ENDREGION}
                                                Result := aSupportType in [ TIPO_SUPPORT_BDR,TIPO_SUPPORT_DVD,TIPO_SUPPORT_CD];
                                                aIsRW   := True;
                                              end
    else
      {$REGION 'Log'}
      {TSI:IGNORE ON}
        WriteLog('TBurningTool.CheckMediaBySupport',Format( 'Unknown media status [ %d ]',[aDataWriter.CurrentPhysicalMediaType]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;

    if Result then
    begin
      Result := aDataWriter.DefaultInterface.IsRecorderSupported(FDiscRecord.DefaultInterface);
      if Not Result then
        {$REGION 'Log'}
        {TSI:IGNORE ON}
          WriteLog('TBurningTool.CheckMediaBySupport',Format( 'IsRecorderSupported is false disk not supported for recording',[]),tplivError);
        {TSI:IGNORE OFF}
        {$ENDREGION}
    end;
  Except on E : Exception do
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.CheckMediaBySupport',Format('Exception [%s] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  End;
end;

Function TBurningTool.CheckMedia(var aDataWriter:TMsftDiscFormat2Data;aIndexDriver:integer;aCheckStatus : Array of Word;var aErrorDisc:boolean;var aCurrentStatus:Word) : Boolean;
var I         : LongInt;
    LsFlag    : Word;

    Procedure SetResult(iCurrenStatus:Word);
    var X: integer;
    begin
      Result := False;
      for X := 0 to Length(aCheckStatus) do
      begin
        if aCheckStatus[X] = iCurrenStatus then
        begin
          Result := True;
          Break;
        end;
      end;
    end;

begin
  Result := False;

  if Not IntFWriterAssigned(aDataWriter) then exit;
  if Not CheckAssignedAndActivationDrive(aIndexDriver) then Exit;
  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.CheckMedia',Format('CheckMedia ',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}

  { IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN
    Indicates that the interface does not know the media state.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK
    Reports information (but not errors) about the media state.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK
    Reports an unsupported media state.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY
    Write operations can occur on used portions of the disc.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_RANDOMLY_WRITABLE
    Media is randomly writable. This indicates that a single session can be written to this disc.
    Note  This value is deprecated and superseded by IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY.

    IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK
    Media has never been used, or has been erased.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE
    Media is appendable (supports multiple sessions).
    IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION
    Media can have only one additional session added to it, or the media does not support multiple sessions.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_DAMAGED
    Media is not usable by this interface. The media might require an erase or other recovery.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED
    Media must be erased prior to use by this interface.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION
    Media has a partially written last session, which is not supported by this interface.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED
    Media or drive is write-protected.
    IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED
    Media cannot be written to (finalized).
    IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA
    Media is not supported by this interface.}

  aErrorDisc := False;
  case aDataWriter.CurrentMediaStatus of
    IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN 			      : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN',tpLivInfo);
                                                            WriteLog('TBurningTool.CheckMedia','The interface does not know the media state',tpLivWarning);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK',tpLivInfo);
                                                            WriteLog('TBurningTool.CheckMedia','Reports information (but not errors) about the media state.',tpLivWarning);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_INFORMATIONAL_MASK);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK   : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK',tpLivInfo);
                                                            WriteLog('TBurningTool.CheckMedia','Reports an unsupported media state.',tplivError);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MASK);
                                                          aErrorDisc       := True;
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY     : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_OVERWRITE_ONLY);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK              : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE         : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION      : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_DAMAGED            : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_DAMAGED',tpLivInfo);
                                                            WriteLog('TBurningTool.CheckMedia','Media is not usable by this interface. The media might require an erase or other recovery.',tplivError);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_FINAL_SESSION);
                                                          aErrorDisc := True;
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED     : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION  : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_NON_EMPTY_SESSION);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED    : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_WRITE_PROTECTED);
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA  : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA',tpLivInfo);
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_UNSUPPORTED_MEDIA);
                                                          aErrorDisc := True;
                                                        end;
    IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED			    : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                            WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED);
                                                        end;

    (IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE+
    IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK )            : begin
                                                          {$REGION 'Log'}
                                                          {TSI:IGNORE ON}
                                                             WriteLog('TBurningTool.CheckMedia','Media state IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE + IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK',tpLivInfo);
                                                          {TSI:IGNORE OFF}
                                                          {$ENDREGION}
                                                          aCurrentStatus := IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK+IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE;
                                                          SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK);
                                                          if Not Result then
                                                            SetResult(IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE);
                                                        end
  else
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.CheckMedia',Format( 'Media state [ %d ]',[aDataWriter.CurrentMediaStatus]),tpLivWarning);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  end;

  if Not Result then
  begin
    LsFlag := 0;
    {Non stampo i log pero effettuo una verifica con operatori BTIWASE}
    for I := 0 to Length(aCheckStatus) do
    begin
      if I = 0 then
        LsFlag := aCheckStatus [I]
      else
        LsFlag := LsFlag or aCheckStatus [I];
    end;

    Result := aDataWriter.CurrentMediaStatus and LsFlag <> 0;
  end;

end;

Function TBurningTool.isDiskEmpty(var aDataWriter:TMsftDiscFormat2Data;aIdexDriver:integer;var aErrorMedia : Boolean) : Boolean;
var LMediaStatus  : Word;
    LChecStatus   : Array of Word;
    LiRetry       : Integer;
    LMax_Retry    : integer;
begin
  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.isDiskEmpty',Format('Check if disk is blank',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  LMax_Retry  := DEFAULT_MAX_RETRY;
  aErrorMedia := False;
  LiRetry     := 0;

  SetLength(LChecStatus,1);
  LChecStatus[0] := IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK;
  repeat
    Result := CheckMedia(aDataWriter,aIdexDriver,LChecStatus,aErrorMedia,LMediaStatus);
    if Not result then
      aErrorMedia := LMediaStatus <> IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN;

    {Faccio al massimo 3 tentatvi poi do errore}
    if not aErrorMedia then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.isDiskEmpty',Format('Retry check media',[]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      Sleep(2000);
      Inc(LiRetry);
      aErrorMedia := LiRetry >= LMax_Retry;
    end

  until result or aErrorMedia or FAbort;

  if FAbort then Exit;

  if not Result then
    Result := aDataWriter.DefaultInterface.MediaHeuristicallyBlank;

  if Result then
   aErrorMedia := False;

  if aErrorMedia then
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.isDiskEmpty',Format('Check media timeout abort',[]),tplivError);
    {TSI:IGNORE OFF}
    {$ENDREGION}

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.isDiskEmpty',Format('Is blank [ %s ]',[BoolToStr(Result,True)]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  SetLength(LChecStatus,0);
end;


Function TBurningTool.isDiskWritable(var aDataWriter:TMsftDiscFormat2Data;aIdexDriver:integer;var aErrorMedia : Boolean) : Boolean;
var LMediaStatus  : Word;
    LChecStatus   : Array of Word;
    LiRetry       : Integer;
    LMax_Retry    : integer;
label RetryChecMedia;
begin
  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.isDicWritable',Format('Check if disk is Re-writable',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  Result  := False;
  LiRetry  := 0;
  SetLength(LChecStatus,4);
  LChecStatus[0] := IMAPI_FORMAT2_DATA_MEDIA_STATE_ERASE_REQUIRED;
  LChecStatus[1] := IMAPI_FORMAT2_DATA_MEDIA_STATE_APPENDABLE;
  LChecStatus[2] := IMAPI_FORMAT2_DATA_MEDIA_STATE_BLANK;
  LChecStatus[3] := IMAPI_FORMAT2_DATA_MEDIA_STATE_FINALIZED;
  LMax_Retry     := DEFAULT_MAX_RETRY;
  RetryChecMedia:
  if Not CheckMedia(aDataWriter,aIdexDriver,LChecStatus,aErrorMedia,LMediaStatus) then
  begin
    if FAbort then Exit;
    {Faccio al massimo 3 tentatvi poi do errore}
    if LMediaStatus = IMAPI_FORMAT2_DATA_MEDIA_STATE_UNKNOWN then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.isDicWritable',Format('Retry check media',[]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      Sleep(2000);
      Inc(LiRetry);

      if LiRetry < LMax_Retry then
        Goto RetryChecMedia
      else
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.isDicWritable',Format('Check media timeout abort',[]),tplivError);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        aErrorMedia := True;
      end;
    end;
  end
  else
    Result := True;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.isDicWritable',Format('Is rewritable [ %s ]',[BoolToStr(Result,True)]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  SetLength(LChecStatus,0);
end;

Procedure TBurningTool.DoOnProgressBurnCustom(Const aSInfo:String;aAllowAbort:Boolean=True);
begin
  if Assigned(FOnProgressBurn) then
  begin
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.DoOnProgressBurnCustom',Format('%s',[aSInfo]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    FOnProgressBurn(self,aSInfo,0,False,False,0,aAllowAbort)
  end;
end;

Function TBurningTool.BurningDiskImage(aIdexDriver,aSupportType:Integer;Const aSPathIso,aCaptionDisk:String;aCheckDisk:Boolean):TStatusBurn;
var LLetterDrive  : String;
    LDriveisRead  : Boolean;
    LiRetry       : Integer;
    LDataWriter   : TMsftDiscFormat2Data;
    LMax_Retry    : Integer;

    Function CheckABort(var OwnerResult : TStatusBurn ) : Boolean;
    begin
      Result := Not FAbort;
      if FAbort then
        OwnerResult := SbAbort;
    end;

    function SetCheckDisk:Boolean;
    begin
      Result := True;
      {Imposto la verifica del disco}
      if aCheckDisk then
      begin
        if Not SetBurnVerification(LDataWriter,IMAPI_BURN_VERIFICATION_FULL) then
        begin
          {$REGION 'Log'}
          {TSI:IGNORE ON}
             WriteLog('TBurningTool.SetCheckDisk',Format('[ SetCheckDisk ] Unable set burn verification last error [ %s ]',[SysErrorMessage(GetLastError)]),tplivError);
          {TSI:IGNORE OFF}
          {$ENDREGION}
          Result := False;
        end;
      end
      else
      begin
        if Not SetBurnVerification(LDataWriter,IMAPI_BURN_VERIFICATION_QUICK) then
          {$REGION 'Log'}
          {TSI:IGNORE ON}
             WriteLog('TBurningTool.SetCheckDisk',Format('[ SetCheckDisk ] Unable set burn verification last error [ %s ]',[SysErrorMessage(GetLastError)]),tpLivWarning);
          {TSI:IGNORE OFF}
          {$ENDREGION}
      end;
    end;
begin
  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.BurningDiskImage',Format('Start function',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}

  Result      := SbError;
  FWriting    := False;
  FAbort      := False;
  LiRetry     := 0;

  if Not FileExists(aSPathIso) then
  begin
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.BurningDiskImage',Format('ISO file not exist [ %s ]',[aSPathIso ]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    Exit;
  end;

  DoOnProgressBurnCustom(Sync_Driver);

  if not CheckAssignedAndActivationDrive(aIdexDriver) then Exit;
  if Not FoundLetterDrive(aIdexDriver,LLetterDrive) then Exit;

  LDataWriter := TMsftDiscFormat2Data.Create(nil);
  Try
    if Not CheckABort(Result) then Exit;

    Try
      LDataWriter.AutoConnect := False;
      LDataWriter.ConnectKind := ckRunningOrNew;
      LDataWriter.ClientName  := ExtractFileName(Application.ExeName);
      LDataWriter.Recorder    := FDiscRecord.DefaultInterface;
      LDataWriter.OnUpdate    := MsftDiscFormat2DataUpdate;

      {Prendo il controllo esclusivo del driver}
      DoOnProgressBurnCustom(Acq_driver);

      {Chiudo il cassetto eventualmente aperto}
      If not CloseTray(aIdexDriver) then exit;
      Sleep(5000);

      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.BurningDiskImage',Format('Check disk status',[]),tpLivInfo);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      DoOnProgressBurnCustom(Verifying_disk);
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.BurningDiskImage',Format('Associating disk record interface',[]),tpLivInfo);
      {TSI:IGNORE OFF}
      {$ENDREGION}

      {Imposto eventuale verifica del disco}
      if Not SetCheckDisk then Exit;

      LMax_Retry := DEFAULT_MAX_RETRY;
      {Verifica disco inserito con eventuale ERASE se abilitato}
      repeat
         if Not CheckABort(Result) then Exit;
         Inc(LiRetry);
         LDriveisRead := MngInsertDisk(aIdexDriver,aSupportType,LDataWriter,LLetterDrive,LiRetry);
         Sleep(5000);
      until ( LDriveisRead ) or ( LiRetry >= LMax_Retry) or ( Result = SbAbort );

      if Not CheckABort(Result) or not LDriveisRead then Exit;

      WriteIso(LDataWriter,aIdexDriver,aSupportType,aCaptionDisk,aSPathIso,Result);
    Except on E : Exception do
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.BurningDiskImage',Format('Exception [ %s ] last error [ %s ]',[e.Message,SysErrorMessage(GetLastError)]),tplivException);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        Result := SbError;
      end;
    End;
  Finally
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.BurningDiskImage',Format('End function disconneting driver',[]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
    FCurrentWriter  := nil;
    LDataWriter.Disconnect;
    LDataWriter.Free;
    if FCancelWriting then
      FOnProgressBurn(self,Cancellation,0,False,True,0,False);
  End;
end;

Function TBurningTool.GetMaxWriteSectorsPerSecondSupported(Const aDataWriter:TMsftDiscFormat2Data;aIndexDriver,aSupportType:Integer) : Integer;

var LSupportWriteSpeedDescriptors : PSafeArray;
    I                             : LongInt;
    LvTmp                         : Variant;
    LLBound                       : LongInt;
    LHBound                       : LongInt;
    LHumanSpeed                   : Integer;

    Function RemoveXHumanSpeed(const LHumanSpeed:string):Integer;
    begin
      Result := StrToIntDef(StringReplace(LHumanSpeed,'X','',[rfIgnoreCase,rfReplaceAll]).Trim,0);
    end;
begin
  Result := -1;
  if Not CheckAssignedAndActivationDrive(aIndexDriver) then Exit;

  Try
    //SupportWriteSpeedDescriptors := DataWriter.SupportedWriteSpeedDescriptors;
    LSupportWriteSpeedDescriptors := aDataWriter.SupportedWriteSpeeds;
    Try
      SafeArrayGetLBound(LSupportWriteSpeedDescriptors, 1, LLBound);
      SafeArrayGetUBound(LSupportWriteSpeedDescriptors, 1, LHBound);
      {Rescrivibili}
      for I := LHBound downto LLBound do
      begin
        SafeArrayGetElement(LSupportWriteSpeedDescriptors, I, LvTmp);

        if VarIsNull(LvTmp) then Continue;
        //if not Supports(vTmp, IWriteSpeedDescriptor, WriteSpeedDescriptor) then Continue;

     //   if ( Result < WriteSpeedDescriptor.WriteSpeed )   then
     //     Result := WriteSpeedDescriptor.WriteSpeed;
        LHumanSpeed := RemoveXHumanSpeed(GetHumanSpeedWrite(LvTmp,aSupportType));
        if Result <= Integer(LvTmp)  then
        begin
            Result := LvTmp;
        end;

        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.GetMaxWriteSectorsPerSecondSupported',Format('Supported write speed [%dX]',[LHumanSpeed]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
      end;
    Finally
      SafeArrayDestroy(LSupportWriteSpeedDescriptors); // cleanup PSafeArray
    End;
  Except on E: Exception do
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.GetMaxWriteSectorsPerSecondSupported',Format('Exception message [ %s ]',[E.Message]),tplivException);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  End;
end;

Function TBurningTool.GetHumanSpeedWrite(aSectorForSecond:Integer;aSupportType:Integer):string;
var LFactor : Integer;
begin
  LFactor := IMAPI_SECTORS_PER_SECOND_AT_1X_CD;
  case aSupportType of
    TIPO_SUPPORT_CD     : LFactor := IMAPI_SECTORS_PER_SECOND_AT_1X_CD;
//    TIPO_SUPPORTO_CD_DL  : Factor := IMAPI_SECTORS_PER_SECOND_AT_1X_CD;
    TIPO_SUPPORT_DVD    : LFactor := IMAPI_SECTORS_PER_SECOND_AT_1X_DVD;
    TIPO_SUPPORT_DVD_DL : LFactor := IMAPI_SECTORS_PER_SECOND_AT_1X_DVD;
    TIPO_SUPPORT_BDR    : LFactor := IMAPI_SECTORS_PER_SECOND_AT_1X_BD;
  end;

  result := Format('%dX',[aSectorForSecond div LFactor]);
end;

procedure TBurningTool.CancelWriting;
begin
  Try
    if assigned(FCurrentWriter) then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.CancelWriting',Format('Request cancel burning',[]),tpLivInfo);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      if FWriting and not FCancelWriting then
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.CancelWriting',Format('Call IMAPI2 cancel burning',[]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        FCurrentWriter.CancelWrite;
      end;
      FCancelWriting := True;
    end;
  Except On E: Exception do
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.CancelWriting',Format('Exception message [ %s ]',[E.Message]),tplivException);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  End;
end;

Procedure TBurningTool.WriteIso(Var  aDataWriter:TMsftDiscFormat2Data;aIndexDriver,aSupportType:Integer;const aCaptionDisk,aPathIso:string;var aStatusWrite : TStatusBurn);
const IMAPI_MEDIA_BUSY = -1062600185;
var LDiscStream : IMAPI2FS_TLB.IStream;
    LIsoLoader  : TMsftIsoImageManager;

    Procedure SetError;
    begin
      Try
        CancelBurning;
      Finally
        aStatusWrite := SbError;
        FWriting    := False;
      End;
    end;

    Procedure InternalWrite;
    begin
      Try

        Try
          (*  Try
              DataWriter.SetWriteSpeed(GetMaxWriteSectorsPerSecondSupported(DataWriter,IndexDriver,TipoSupporto),WordBool(0));
            Except
              on E : EOleException do
                {$REGION 'Log'}
                {TSI:IGNORE ON}
                   WriteLog('TBurningTool.InternalWrite[SetWriteSpeed]',Format('Exception Ole [ %d ] message [ %s ] ',[E.ErrorCode,E.Message]),tplivException);
                {TSI:IGNORE OFF}
                {$ENDREGION}
              On E: Exception do
              {$REGION 'Log'}
              {TSI:IGNORE ON}
                 WriteLog('TBurningTool.InternalWrite[SetWriteSpeed]',Format('Exception message [ %s ] ',[E.Message]),tplivException);
              {TSI:IGNORE OFF}
              {$ENDREGION}
            End;
            *)
          {$REGION 'Log'}
          {TSI:IGNORE ON}
             WriteLog('TBurningTool.InternalWrite',Format('Start writing disk,speed of %s has been set',[GetHumanSpeedWrite(aDataWriter.CurrentWriteSpeed,aSupportType)]),tpLivInfo);
          {TSI:IGNORE OFF}
          {$ENDREGION}
          FWriting       := True;
          FCurrentWriter := aDataWriter;
          aStatusWrite    := SbBurning;
          aDataWriter.Write(IMAPI2_TLB.IStream(LDiscStream));

          if FAbort then Exit;

          if Assigned(FOnProgressBurn) then
            FOnProgressBurn(self,Burn_completed,0,True,False,0,True);
          DriveEject(aIndexDriver);
          aStatusWrite := SbBurned;

        Except

          on E : EOleException do
          begin
            SetError;
            if IMAPI_MEDIA_BUSY = E.ErrorCode then
              {$REGION 'Log'}
              {TSI:IGNORE ON}
                 WriteLog('TBurningTool.InternalWrite',Format('E_IMAPI_RECORDER_MEDIA_BUSY Ole [ %d ] message [ %s ]',[E.ErrorCode,E.Message]),tpLivWarning)
              {TSI:IGNORE OFF}
              {$ENDREGION}
            else
              {$REGION 'Log'}
              {TSI:IGNORE ON}
                 WriteLog('TBurningTool.InternalWrite',Format('Exception Ole [ %d ] message [ %s ] ',[E.ErrorCode,E.Message]),tplivException);
              {TSI:IGNORE OFF}
              {$ENDREGION}
          end;

          On E: Exception do
          begin
            {$REGION 'Log'}
            {TSI:IGNORE ON}
               WriteLog('TBurningTool.InternalWrite',Format('Exception message [ %s ]',[E.Message]),tplivException);
            {TSI:IGNORE OFF}
            {$ENDREGION}
            SetError;
          end;

        End;
      Finally
       // FDiscRecord.ReleaseExclusiveAccess;
      End;

    end;
begin
  if Not CheckAssignedAndActivationDrive(aIndexDriver) then Exit;

  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.WriteIso',Format('Create ISO file loader',[]),tpLivInfo);
  {TSI:IGNORE OFF}
  {$ENDREGION}
  LDiscStream     := nil;
  FCancelWriting := False;
  LIsoLoader      := TMsftIsoImageManager.Create(nil);
  Try
    Try
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.WriteIso',Format('Load ISO file on stream [%s]',[aPathIso]),tpLivInfo);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      if LIsoLoader.SetPath(aPathIso) <> S_OK then
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.WriteIso',Format('Unable load ISO file [ %s ]',[aPathIso]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        Exit;
      end;

      if LIsoLoader.DefaultInterface.Get_Stream(LDiscStream) <> S_OK then
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.WriteIso',Format('Unable load stream of ISO file [ %s ]',[aPathIso]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        Exit;
      end;

      InternalWrite;
    Except
      On E: Exception do
      begin
        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.WriteIso',Format('Exception message [ %s ]',[E.Message]),tplivException);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        SetError;
      end;
    End;
  Finally
    LDiscStream := nil;
    LIsoLoader.Free;
    FWriting := False;
  End;
end;

Function TBurningTool.MngInsertDisk(aIdexDriver,aSupportType:Integer;var aDataWriter:TMsftDiscFormat2Data;const aLetterDrive:String;var aIRetry:Integer):Boolean;
var LisSupportRW : Boolean;
    LisEmpy      : Boolean;
    LisDiskRW    : Boolean;
    LErrorMedia  : Boolean;
    LDiskPresent : Boolean;
    LsMsg        : String;
begin
  Result      := False;
  LisSupportRW := False;
  LErrorMedia  := False;
  LisEmpy      := False;
  LisDiskRW    := False;
  LDiskPresent := False;
  LsMsg        := Format(Insert_disk,[aLetterDrive]);

  {Verifico se nell'unit� � presente almeno un disco altrimenti lo richiedo}
  if DiskIsPresentOnDrive(aIdexDriver,aDataWriter) then
  begin
    LDiskPresent := True;
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.MngInsertDisk',Format('Found disk on drive',[]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}

    DoOnProgressBurnCustom(Disk_detected);

    {Verifico se nell'unita c'� un disco idoneo al supporto}
    if CheckMediaBySupport(aIdexDriver,aSupportType,LisSupportRW,aDataWriter) then
    begin
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.MngInsertDisk',Format('Disk type is valid',[]),tpLivInfo);
      {TSI:IGNORE OFF}
      {$ENDREGION}
      DoOnProgressBurnCustom(Invalid_Disk);


      {Verifico se nell'unitca c'� un disco vuoto}
      
      LisEmpy := isDiskEmpty(aDataWriter,aIdexDriver,LErrorMedia);

      if FAbort then Exit;

      if Not LisEmpy then
      begin
        DoOnProgressBurnCustom(Disk_not_empty);
        LsMsg := Format(Insert_empty_disk,[aLetterDrive]);

        {$REGION 'Log'}
        {TSI:IGNORE ON}
           WriteLog('TBurningTool.MngInsertDisk',Format('disk on drive letter [ %s ] is not empty ',[aLetterDrive]),tpLivInfo);
        {TSI:IGNORE OFF}
        {$ENDREGION}
        {verifico se nell'unit� c'� un dico rescrivibile}
        if LisSupportRW then
          LisDiskRW := isDiskWritable(aDataWriter,aIdexDriver,LErrorMedia);
      end
      else
        DoOnProgressBurnCustom(Disk_is_empty);
    end
    else
    begin
      LsMsg := Format(Invalid_disk_for_driver,[aLetterDrive]);
      {$REGION 'Log'}
      {TSI:IGNORE ON}
         WriteLog('TBurningTool.MngInsertDisk',Format('support on drive is not usable with this type of ISO idTypeSypport [ %d ]',[aSupportType]),tpLivWarning);
      {TSI:IGNORE OFF}
      {$ENDREGION}
    end;
  end
  else
  begin
    DoOnProgressBurnCustom(Disk_request);
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.MngInsertDisk',Format('No disk on drive [ %s ]',[aLetterDrive]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  end;

  if FAbort then Exit;
  if Not LDiskPresent and ( aIRetry < DEFAULT_MAX_RETRY )  then Exit;

  {Sono sicuro che ci sia un disco nell'unit� ora verifico se � vuoto}
  if ( Not LisEmpy ) then
  begin
    {Disco riscrivibile AUTO ERASE o ERASE su richiesta configurabile da Regedit quindi per singolo OW }
    if ( not CanErase and not EraseCDAuto ) or
       ( not IsDriverRW(aIdexDriver,aSupportType) or ( not LisDiskRW ) )
    then
    begin
      DriveEject(aIdexDriver);
      if MessageBox(0, Pchar(LsMsg), PChar(Application.Title),
                       MB_ICONINFORMATION or MB_OK or MB_OKCANCEL or MB_TOPMOST ) in [idOk]
      then
      begin
        if not CloseTray(aIdexDriver) then Exit;
        aIRetry := 0;
      end
      else
        FAbort := True;
    end
    else
    begin
      if CanErase and not EraseCDAuto then
      begin
        {Cancellazione del disco con richiesta utente}
        if MessageBox(0, Pchar(Format(Erase_request,[aLetterDrive])),
                         PChar(Application.Title),
                         MB_ICONINFORMATION or MB_OK or MB_OKCANCEL or MB_TOPMOST ) in [idOk]
        then
          Result := EraseDisk(aIdexDriver,aSupportType,False)
        else
          FAbort := True;
      end
      else
        {AUTO Erase del disco in automatico senza richiesta}
        Result := EraseDisk(aIdexDriver,aSupportType,False);
    end;
  end
  else
  begin
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.MngInsertDisk',Format('disk on drive letter [ %s ] is empty ',[aLetterDrive]),tpLivInfo);
    {TSI:IGNORE OFF}
    {$ENDREGION}

    if LisSupportRW then
    begin
      if CanErase then
        Result := True
      else
      begin
        DriveEject(aIdexDriver);
        {Dischi riscrivibili non ammessi}
        if MessageBox(0, Pchar(Format(Burn_Not_possible_rw,[aLetterDrive])),
                         PChar(Application.Title),
                       MB_ICONINFORMATION or MB_OK or MB_OKCANCEL or MB_TOPMOST ) in [idOk]
        then
        begin
          if not CloseTray(aIdexDriver) then Exit;
          aIRetry := 0;
        end
        else
          FAbort := True;
      end;
    end;
      Result := True;
  end;
end;

function TBurningTool.GetBitmapDriver( Const aDrive: String): Integer;
var LInfo   : TSHFileInfo;
    LsDrive : string;
begin
  Result := -1;
  if not Assigned(FimgListSysSmall) then Exit;
  LsDrive := aDrive;
  if Pos(']',aDrive) > 0 then
  begin
    LsDrive := Trim( Copy( aDrive,2,Pos(']',aDrive) -1 ) );
    LsDrive := StringReplace(LsDrive,']','',[rfReplaceAll]);
  end;

  SHGetFileInfo(PChar(LsDrive+'\'), 0, LInfo, SizeOf(TSHFileInfo), SHGFI_SYSICONINDEX or SHGFI_DISPLAYNAME);
  Result := LInfo.iIcon;
end;

function TBurningTool.GetCanBurnCD: Boolean;
begin
  Result := FListaDriveCD.Count > 0;
end;

function TBurningTool.GetCanBurnCD_DL: Boolean;
begin
  Result := FListaDriveCD_DL.Count > 0;
end;

function TBurningTool.GetCanBurnDBR: Boolean;
begin
  Result := FListaDriveBDR.Count > 0;
end;

function TBurningTool.GetCanBurnDVD_DL: Boolean;
begin
  Result := FListaDriveDVD_DL.Count > 0;
end;

function TBurningTool.GetCanBurnDVD: Boolean;
begin
  Result := FListaDriveDVD.Count > 0;
end;

function TBurningTool.GetSystemCanBurn: Boolean;
begin
  Result := CanBurnCD or CanBurnCD_DL or CanBurnDVD or CanBurnBDR or CanBurnDVD_DL;
end;

function TBurningTool.SecondToTime(const aSeconds: Cardinal): Double;
var ms, ss, mm, hh, dd: Cardinal;
begin
  dd     := aSeconds div SecsPerDay;
  hh     := (aSeconds mod SecsPerDay) div SecsPerHour;
  mm     := ((aSeconds mod SecsPerDay) mod SecsPerHour) div SecsPerMin;
  ss     := ((aSeconds mod SecsPerDay) mod SecsPerHour) mod SecsPerMin;
  ms     := 0;
  Result := dd + EncodeTime(hh, mm, ss, ms);
end;

procedure TBurningTool.MsftEraseDataUpdate(ASender: TObject; const object_: IDispatch; elapsedSeconds: Integer; estimatedTotalSeconds: Integer);
var LSInfo      : String;
    LCurDiscF2D : IDiscFormat2Erase;
begin
  LSInfo         := LSInfo;
  LCurDiscF2D    := object_ as  IDiscFormat2Erase;
  LSInfo         := Format(Time_progress_Format,
                         [sLineBreak,TimeToStr(SecondToTime(elapsedSeconds)),sLineBreak,TimeToStr(SecondToTime(estimatedTotalSeconds))]);
  if Assigned(FOnProgressBurn) then
    FOnProgressBurn(self,LSInfo,0,False,False,0,False);
  Application.ProcessMessages;
end;

procedure TBurningTool.MsftDiscFormat2DataUpdate(ASender: TObject;const object_, progress: IDispatch);
var LCurProgress     : IDiscFormat2DataEventArgs;
    LCurDiscF2D      : IDiscFormat2Data;
    LWrittensectors  : int64;
    LSInfo           : String;
    LpPosition       : Int64;
    LSetPosition     : Boolean;
    LTime           : String;
    LAllowAbort      : Boolean;
begin
  LCurProgress   := progress as IDiscFormat2DataEventArgs;
  LCurDiscF2D    := object_ as IDiscFormat2Data;
  LSetPosition   := False;
  LpPosition     := 0;
  LAllowAbort    := False;
  {$REGION 'Log'}
  {TSI:IGNORE ON}
     WriteLog('TBurningTool.MsftDiscFormat2DataUpdate',Format('CurProgress.CurrentAction [ %d ]',[LCurProgress.CurrentAction]),tpLivInfo,True);
  {TSI:IGNORE OFF}
  {$ENDREGION}

  case LCurProgress.CurrentAction of
    IMAPI_FORMAT2_DATA_WRITE_ACTION_VALIDATING_MEDIA      :
          LSInfo := Disk_validation;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_FORMATTING_MEDIA      :
          LSInfo := Disk_formatting;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_INITIALIZING_HARDWARE :
          LSInfo := init_hw;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_CALIBRATING_POWER     :
          LSInfo := Laser_calibration;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_WRITING_DATA          :
          begin
            LSInfo            := Disk_writing;
            LWrittensectors   := LCurProgress.LastWrittenLba - LCurProgress.StartLba;
            LpPosition        := Round( (LWrittensectors/LCurProgress.SectorCount) *100 );
            LSetPosition      := True;
            LAllowAbort       := True;
          end;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_FINALIZATION          :
          LSInfo := Finalization_str;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_COMPLETED             :
          begin
            LSInfo    := Burn_completed;
            FWriting := False;
          end;

    IMAPI_FORMAT2_DATA_WRITE_ACTION_VERIFYING             :
          begin
            LSInfo        := Verifying_disk;
            LpPosition    :=  ( LCurProgress.ElapsedTime * 100 ) div LCurProgress.TotalTime ;
            LSetPosition  := True;
          end;
  else
    {$REGION 'Log'}
    {TSI:IGNORE ON}
       WriteLog('TBurningTool.MsftDiscFormat2DataUpdate',Format('Unknow status[ %d ]',[LCurProgress.CurrentAction]),tplivError);
    {TSI:IGNORE OFF}
    {$ENDREGION}
  end;

  if Assigned(FOnProgressBurn) then
  begin
    LTime           := Format(Time_progress,
                      [TimeToStr(SecondToTime(LCurProgress.ElapsedTime)),sLineBreak,
                       TimeToStr(SecondToTime(LCurProgress.TotalTime))]);

    LSInfo := Format('%s%s%s',[LSInfo,sLineBreak,LTime]);
    FOnProgressBurn(self,LSInfo,LpPosition,LSetPosition,False,LCurProgress.CurrentAction,LAllowAbort);
  end;

  if FAbort then
  begin
    CancelWriting;
    Application.ProcessMessages;
    if LCurProgress.CurrentAction = IMAPI_FORMAT2_DATA_WRITE_ACTION_FINALIZATION then
      FWriting := False;
    LSInfo := Burning_Aboring;
    if Assigned(FOnProgressBurn) then
      FOnProgressBurn(self,LSInfo,LpPosition,LSetPosition,False,0,False);
  end;

  Application.ProcessMessages;
end;

end.
