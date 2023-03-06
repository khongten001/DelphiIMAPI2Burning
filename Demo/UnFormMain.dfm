object Form2: TForm2
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Burning demo'
  ClientHeight = 567
  ClientWidth = 1058
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object cxGroupBox1: TPanel
    Left = 0
    Top = 70
    Width = 776
    Height = 497
    Align = alClient
    ParentBackground = False
    TabOrder = 0
    object cxLabel1: TLabel
      AlignWithMargins = True
      Left = 16
      Top = 51
      Width = 756
      Height = 13
      Margins.Left = 15
      Margins.Top = 5
      Align = alTop
      Caption = 'Burning progress.'
      Transparent = True
      ExplicitWidth = 85
    end
    object LDrive: TLabel
      AlignWithMargins = True
      Left = 16
      Top = 6
      Width = 756
      Height = 13
      Margins.Left = 15
      Margins.Top = 5
      Align = alTop
      Caption = 'Select driver'
      Transparent = True
      ExplicitWidth = 60
    end
    object PBurn: TProgressBar
      AlignWithMargins = True
      Left = 16
      Top = 67
      Width = 744
      Height = 25
      Margins.Left = 15
      Margins.Right = 15
      Align = alTop
      TabOrder = 0
    end
    object CBDriver: TcxImageComboBox
      AlignWithMargins = True
      Left = 16
      Top = 22
      Margins.Left = 15
      Margins.Right = 300
      Align = alTop
      Properties.ImmediatePost = True
      Properties.ImmediateUpdateText = True
      Properties.Items = <>
      Properties.ReadOnly = False
      Style.LookAndFeel.NativeStyle = False
      StyleDisabled.LookAndFeel.NativeStyle = False
      StyleFocused.LookAndFeel.NativeStyle = False
      StyleHot.LookAndFeel.NativeStyle = False
      TabOrder = 1
      Width = 459
    end
    object cxGroupBox6: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 283
      Width = 768
      Height = 54
      Align = alTop
      ParentBackground = False
      TabOrder = 3
      object LstatusCheckFile: TLabel
        Left = 91
        Top = 1
        Width = 3
        Height = 52
        Align = alLeft
        Transparent = True
        ExplicitHeight = 13
      end
      object LVerifica: TLabel
        AlignWithMargins = True
        Left = 124
        Top = 4
        Width = 62
        Height = 49
        Margins.Left = 30
        Align = alLeft
        Caption = 'Status verify'
        Transparent = True
        ExplicitHeight = 13
      end
      object CkCheckFinalFile: TToggleSwitch
        AlignWithMargins = True
        Left = 16
        Top = 4
        Width = 72
        Height = 46
        Margins.Left = 15
        Align = alLeft
        TabOrder = 0
        ExplicitHeight = 20
      end
      object PVerifica: TProgressBar
        AlignWithMargins = True
        Left = 192
        Top = 16
        Width = 418
        Height = 22
        Margins.Top = 15
        Margins.Bottom = 15
        Align = alLeft
        TabOrder = 1
      end
    end
    object cxGroupBox14: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 98
      Width = 768
      Height = 179
      Align = alTop
      Ctl3D = False
      ParentBackground = False
      ParentCtl3D = False
      TabOrder = 2
      object LInfoBurn: TLabel
        AlignWithMargins = True
        Left = 31
        Top = 21
        Width = 721
        Height = 152
        Margins.Left = 30
        Margins.Top = 20
        Margins.Right = 15
        Margins.Bottom = 5
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        Transparent = True
        ExplicitWidth = 3
        ExplicitHeight = 13
      end
    end
    object BCancel: TButton
      Left = 680
      Top = 448
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 4
      OnClick = BCancelClick
    end
    object Button2: TButton
      Left = 599
      Top = 448
      Width = 75
      Height = 25
      Caption = 'Burn'
      TabOrder = 5
      OnClick = Button2Click
    end
  end
  object cxGroupBox7: TPanel
    Left = 0
    Top = 0
    Width = 1058
    Height = 70
    Align = alTop
    ParentBackground = False
    TabOrder = 1
    object ImgTipoSupporto: TImage
      AlignWithMargins = True
      Left = 977
      Top = 4
      Width = 77
      Height = 62
      Align = alRight
      Picture.Data = {
        0B546478504E47496D61676589504E470D0A1A0A0000000D4948445200000028
        0000002808060000008CFEB86D000000017352474200AECE1CE9000000046741
        4D410000B18F0BFC6105000000097048597300000EBC00000EBC0195BC724900
        000727494441545847B598694C54571886B5B5C66EB18B49135363973F6D1571
        410541A3698DD1D444FE6817346AD3A6EAB8C0002E54D36AA988B6584DA8C5D8
        1AAD50039401C4A5D10A6E6830D5B6239A6A44D10A6E5841C0012EA7EF7BE6DE
        F1CC9DC30CD2F623CFCC39DF59BE77CE76CFA59B10A24B8C59523C11A483BDE0
        4F7013D48053E047900006EADA3E0C5A67470C72E48D1E382FB714814528A293
        8BC448A74BC42417B58639F236F49B95FDA4AECF50689D76D07904825E64E098
        E442AD20158A9B9AB65F6C2C768B714B8BC590853F895149850242B7E9FA0F86
        D6A9824E73D4E01068A8791D23125CE2DBDD67D1DC6B472B6BA5600A1DBDB848
        E0074F865B1BCF8ED64938250876CB1EBC330229C47DA90EDDF8DBEE93D56204
        A63D2A518E66165CDAD82A5A27C4F5D50526A104728422120AD08DDEDA0C434C
        C3680E471DD4DF0F975683458003E29EB607550925300A6B6D6EE6617415DC1C
        DF1C1111F152E41E640374580438D0A04E0D682794408E4C76E9797415DAE664
        1EB1A63B15D9002DC42F838A3B75415542090C5F902FAA6F34A0BBD05653D728
        8671E3A01D662E1C2E3F3DC49740051E25DAA02AC104C660FD91CE58F9D95A31
        6C9177579BEDB9ABFCC4115F0215AAAD40C108263032D12552B657A0BBE096B5
        B752E0C057C5493083F3501C28100563D58AC10826904F8EF585BFA3CB8E6D61
        D631EF79A8690F3CA8A21558A6A9AC452790D3CAC5CEA7050F698EE4CE4317D0
        F5036BBCDF2226AFDC8772B973EDDC057F330D2D9350DD5FA0523124AA400A1B
        8A7534168F33E7E67231E3AB83189D7C399283B159B84B6995D577E02B903F40
        EDCBA412F401CF80731058424D16D6AD44D7508B25D0BA0C1CF8ED2A35F8ECBE
        A74D2CD97A420C81408ED6CC8C5211811FC11F63EFCBC471BD28EE855BBBA63F
        87F467F4C1FC04A699153B050532D8284C634313978CD75A5ADBCC94D7324BCE
        C85DCA51B36F06852BA03704AEBA591C3701E929F463145F41173E81FBE8EC2C
        14C8457ED85D2385D092BE2F1783E6E7893118D5438AFFFD75BF7434AD84CFF9
        6854EB06810202A7223F8A6510388D7E4281BC6CEA3AD08280C68415BB195FDA
        82ACA362787CC1AFA007462CF28DB9B9E2DC55EF45E1C8991A398A9A7E0E0239
        4A1077C114F8367CE3580E81292C231418706309C6C88402E3D31D27195FDCBD
        E7116138CF4626B81EB33A1CE4C85DE0DC522ECB5BDA8C6DE1F3F379F1586BB6
        F78024D003A20680468A3305BE06FF4CD683C00CAB3F0AE4353D404847443A5D
        463C76ACD7DABDBB36C1351A19D96154922B373DFFB42CADAB6FA688C7D18EBB
        B4197C04BAC3B7C61266C1B6285B07287039F3844EBE4368C5E8E01AE4EEB52C
        A7EC82787D4E2EA732313AC995178D1BB7B961DC287B04C11D4833CE26C0FC56
        5598C925B3CE01900E813D982774F205472B460705F2F8D850E4467BAF95B9AF
        8959EB4BC5CA9C93A2D9D36A7AC5C708CCA9E4D58671FA221D660AB2B303E58F
        006B8453C0BB6CC7864EA015A3232AD16544E2A9811728517CE2B254A2B1BFDE
        49DFFF04827C0E9A9197A3817436D0095C8ABE7B824791CEA0EF46515C4FB6A1
        C08156F050F0823923A3D4F8645B85188AA38657AB459B8F897357EE50949C5A
        D7F12A317659F152539014C0B499BF66F96CCC37CB9FB27C561BF981E0AD7631
        2A3C68B11BC58A1FE4EE35F8B13AF794BC915034CFC5708C28EB20DF8257CD7E
        08F2A1150CBCCA38F8F6283E950D66799CE5639EC80F4CD7469D30C2A70616AD
        C83F7A918D447B7BBB14483B8B918BC70842107E84AF4D05E03A3A6D05037257
        E2FB96E2539177417C2F567C11F449812FCEDCD11B8B9F1BA09D9B400AC3378F
        944867A18129A428A3DD300C08E49734FA4874B20B14B6A14D13D8C43E954084
        F5E82BB1F955DE047395FC16B69102094671BB390212BE5BC4A6FE2C9A1EEC4A
        69A6309FFD51755B4E31DACC067C551D00BA5F73BD278061C2B41BAC36D3965F
        2D6F00B1665A027B201057FEEE144678CE256D39CE0A016617C8E306EFBA4D68
        D70BBFBA3F5CB23F65241E06FB269AE21348B0D662B9E6C62FE7954C6F7681B1
        A9FB78F56A8340EEC04CD00B6E0A3C6F06F937E4F8092408F41D6FC4B3BF2E43
        36D05481F79A5AC460DC62CC0D1286B38B6B8857690A5CA104EA2A9702041204
        2BE31A9CF1E54164FD4D15B8ABE2B2F5F24D3EB85D32BDBFD971368ABB3ACD2A
        6D5A810401F760178BB7524A44D5F57AB8BCA60A4CC43AE553C5149803174535
        989D6F075F98E9AE725F2BCE026B329557FB704CE31ADC50DAF1A71A5F9094DB
        325F7A9E45A7496A0025DD152AB4C254F8C60F117514C317A4B4DC53466D5DA3
        A8AAADB78E171527DB68027595855A513A309A0E08F5F026C337B6311839CDBB
        06FF0DDC071D4FB205EA128CAB15130C3C7F27E150DFA51167C17F78F256B2D6
        1EF02189643CAD88CE82517D194C01CB400648030ED08FE508127073EE24E3AD
        180141FF6B102C06D42BC183510E9E57DBFB75F67F82C013410EB80A2C41F700
        45AD022F05B613DDFE013F1654F476967B5D0000000049454E44AE426082}
      Transparent = True
      ExplicitLeft = 949
      ExplicitTop = 5
      ExplicitHeight = 56
    end
  end
  object Memo1: TMemo
    Left = 776
    Top = 70
    Width = 282
    Height = 497
    Align = alRight
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
  end
  object OpenDialog1: TOpenDialog
    Left = 640
    Top = 430
  end
end
