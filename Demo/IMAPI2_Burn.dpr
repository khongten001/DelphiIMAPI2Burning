program IMAPI2_Burn;

uses
  Vcl.Forms,
  UnFormMain in 'UnFormMain.pas' {Form2},
  IMAPI2_TLB in '..\Source\IMAPI2_TLB.pas',
  IMAPI2FS_TLB in '..\Source\IMAPI2FS_TLB.pas',
  UnBurningUtility in '..\Source\UnBurningUtility.pas',
  UnBurningUtility.resource in '..\Source\UnBurningUtility.resource.pas',
  UnBurningUtility.Types in '..\Source\UnBurningUtility.Types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
