module HIDAPI
  ##
  # List of all known USB languages.
  class Language

    KNOWN = {
        AFRIKAANS:                      {name: "Afrikaans", code: "af", usb_code: 0x0436},
        ALBANIAN:                       {name: "Albanian", code: "sq", usb_code: 0x041c},
        ARABIC___UNITED_ARAB_EMIRATES:  {name: "Arabic - United Arab Emirates", code: "ar_ae", usb_code: 0x3801},
        ARABIC___BAHRAIN:               {name: "Arabic - Bahrain", code: "ar_bh", usb_code: 0x3c01},
        ARABIC___ALGERIA:               {name: "Arabic - Algeria", code: "ar_dz", usb_code: 0x1401},
        ARABIC___EGYPT:                 {name: "Arabic - Egypt", code: "ar_eg", usb_code: 0x0c01},
        ARABIC___IRAQ:                  {name: "Arabic - Iraq", code: "ar_iq", usb_code: 0x0801},
        ARABIC___JORDAN:                {name: "Arabic - Jordan", code: "ar_jo", usb_code: 0x2c01},
        ARABIC___KUWAIT:                {name: "Arabic - Kuwait", code: "ar_kw", usb_code: 0x3401},
        ARABIC___LEBANON:               {name: "Arabic - Lebanon", code: "ar_lb", usb_code: 0x3001},
        ARABIC___LIBYA:                 {name: "Arabic - Libya", code: "ar_ly", usb_code: 0x1001},
        ARABIC___MOROCCO:               {name: "Arabic - Morocco", code: "ar_ma", usb_code: 0x1801},
        ARABIC___OMAN:                  {name: "Arabic - Oman", code: "ar_om", usb_code: 0x2001},
        ARABIC___QATAR:                 {name: "Arabic - Qatar", code: "ar_qa", usb_code: 0x4001},
        ARABIC___SAUDI_ARABIA:          {name: "Arabic - Saudi Arabia", code: "ar_sa", usb_code: 0x0401},
        ARABIC___SYRIA:                 {name: "Arabic - Syria", code: "ar_sy", usb_code: 0x2801},
        ARABIC___TUNISIA:               {name: "Arabic - Tunisia", code: "ar_tn", usb_code: 0x1c01},
        ARABIC___YEMEN:                 {name: "Arabic - Yemen", code: "ar_ye", usb_code: 0x2401},
        ARMENIAN:                       {name: "Armenian", code: "hy", usb_code: 0x042b},
        AZERI___LATIN:                  {name: "Azeri - Latin", code: "az_az", usb_code: 0x042c},
        AZERI___CYRILLIC:               {name: "Azeri - Cyrillic", code: "az_az", usb_code: 0x082c},
        BASQUE:                         {name: "Basque", code: "eu", usb_code: 0x042d},
        BELARUSIAN:                     {name: "Belarusian", code: "be", usb_code: 0x0423},
        BULGARIAN:                      {name: "Bulgarian", code: "bg", usb_code: 0x0402},
        CATALAN:                        {name: "Catalan", code: "ca", usb_code: 0x0403},
        CHINESE___CHINA:                {name: "Chinese - China", code: "zh_cn", usb_code: 0x0804},
        CHINESE___HONG_KONG_SAR:        {name: "Chinese - Hong Kong SAR", code: "zh_hk", usb_code: 0x0c04},
        CHINESE___MACAU_SAR:            {name: "Chinese - Macau SAR", code: "zh_mo", usb_code: 0x1404},
        CHINESE___SINGAPORE:            {name: "Chinese - Singapore", code: "zh_sg", usb_code: 0x1004},
        CHINESE___TAIWAN:               {name: "Chinese - Taiwan", code: "zh_tw", usb_code: 0x0404},
        CROATIAN:                       {name: "Croatian", code: "hr", usb_code: 0x041a},
        CZECH:                          {name: "Czech", code: "cs", usb_code: 0x0405},
        DANISH:                         {name: "Danish", code: "da", usb_code: 0x0406},
        DUTCH___NETHERLANDS:            {name: "Dutch - Netherlands", code: "nl_nl", usb_code: 0x0413},
        DUTCH___BELGIUM:                {name: "Dutch - Belgium", code: "nl_be", usb_code: 0x0813},
        ENGLISH___AUSTRALIA:            {name: "English - Australia", code: "en_au", usb_code: 0x0c09},
        ENGLISH___BELIZE:               {name: "English - Belize", code: "en_bz", usb_code: 0x2809},
        ENGLISH___CANADA:               {name: "English - Canada", code: "en_ca", usb_code: 0x1009},
        ENGLISH___CARIBBEAN:            {name: "English - Caribbean", code: "en_cb", usb_code: 0x2409},
        ENGLISH___IRELAND:              {name: "English - Ireland", code: "en_ie", usb_code: 0x1809},
        ENGLISH___JAMAICA:              {name: "English - Jamaica", code: "en_jm", usb_code: 0x2009},
        ENGLISH___NEW_ZEALAND:          {name: "English - New Zealand", code: "en_nz", usb_code: 0x1409},
        ENGLISH___PHILLIPPINES:         {name: "English - Phillippines", code: "en_ph", usb_code: 0x3409},
        ENGLISH___SOUTHERN_AFRICA:      {name: "English - Southern Africa", code: "en_za", usb_code: 0x1c09},
        ENGLISH___TRINIDAD:             {name: "English - Trinidad", code: "en_tt", usb_code: 0x2c09},
        ENGLISH___GREAT_BRITAIN:        {name: "English - Great Britain", code: "en_gb", usb_code: 0x0809},
        ENGLISH___UNITED_STATES:        {name: "English - United States", code: "en_us", usb_code: 0x0409},
        ESTONIAN:                       {name: "Estonian", code: "et", usb_code: 0x0425},
        FARSI:                          {name: "Farsi", code: "fa", usb_code: 0x0429},
        FINNISH:                        {name: "Finnish", code: "fi", usb_code: 0x040b},
        FAROESE:                        {name: "Faroese", code: "fo", usb_code: 0x0438},
        FRENCH___FRANCE:                {name: "French - France", code: "fr_fr", usb_code: 0x040c},
        FRENCH___BELGIUM:               {name: "French - Belgium", code: "fr_be", usb_code: 0x080c},
        FRENCH___CANADA:                {name: "French - Canada", code: "fr_ca", usb_code: 0x0c0c},
        FRENCH___LUXEMBOURG:            {name: "French - Luxembourg", code: "fr_lu", usb_code: 0x140c},
        FRENCH___SWITZERLAND:           {name: "French - Switzerland", code: "fr_ch", usb_code: 0x100c},
        GAELIC___IRELAND:               {name: "Gaelic - Ireland", code: "gd_ie", usb_code: 0x083c},
        GAELIC___SCOTLAND:              {name: "Gaelic - Scotland", code: "gd", usb_code: 0x043c},
        GERMAN___GERMANY:               {name: "German - Germany", code: "de_de", usb_code: 0x0407},
        GERMAN___AUSTRIA:               {name: "German - Austria", code: "de_at", usb_code: 0x0c07},
        GERMAN___LIECHTENSTEIN:         {name: "German - Liechtenstein", code: "de_li", usb_code: 0x1407},
        GERMAN___LUXEMBOURG:            {name: "German - Luxembourg", code: "de_lu", usb_code: 0x1007},
        GERMAN___SWITZERLAND:           {name: "German - Switzerland", code: "de_ch", usb_code: 0x0807},
        GREEK:                          {name: "Greek", code: "el", usb_code: 0x0408},
        HEBREW:                         {name: "Hebrew", code: "he", usb_code: 0x040d},
        HINDI:                          {name: "Hindi", code: "hi", usb_code: 0x0439},
        HUNGARIAN:                      {name: "Hungarian", code: "hu", usb_code: 0x040e},
        ICELANDIC:                      {name: "Icelandic", code: "is", usb_code: 0x040f},
        INDONESIAN:                     {name: "Indonesian", code: "id", usb_code: 0x0421},
        ITALIAN___ITALY:                {name: "Italian - Italy", code: "it_it", usb_code: 0x0410},
        ITALIAN___SWITZERLAND:          {name: "Italian - Switzerland", code: "it_ch", usb_code: 0x0810},
        JAPANESE:                       {name: "Japanese", code: "ja", usb_code: 0x0411},
        KOREAN:                         {name: "Korean", code: "ko", usb_code: 0x0412},
        LATVIAN:                        {name: "Latvian", code: "lv", usb_code: 0x0426},
        LITHUANIAN:                     {name: "Lithuanian", code: "lt", usb_code: 0x0427},
        F_Y_R_O__MACEDONIA:             {name: "F.Y.R.O. Macedonia", code: "mk", usb_code: 0x042f},
        MALAY___MALAYSIA:               {name: "Malay - Malaysia", code: "ms_my", usb_code: 0x043e},
        MALAY___BRUNEI:                 {name: "Malay – Brunei", code: "ms_bn", usb_code: 0x083e},
        MALTESE:                        {name: "Maltese", code: "mt", usb_code: 0x043a},
        MARATHI:                        {name: "Marathi", code: "mr", usb_code: 0x044e},
        NORWEGIAN___BOKML:              {name: "Norwegian - Bokml", code: "no_no", usb_code: 0x0414},
        NORWEGIAN___NYNORSK:            {name: "Norwegian - Nynorsk", code: "no_no", usb_code: 0x0814},
        POLISH:                         {name: "Polish", code: "pl", usb_code: 0x0415},
        PORTUGUESE___PORTUGAL:          {name: "Portuguese - Portugal", code: "pt_pt", usb_code: 0x0816},
        PORTUGUESE___BRAZIL:            {name: "Portuguese - Brazil", code: "pt_br", usb_code: 0x0416},
        RAETO_ROMANCE:                  {name: "Raeto-Romance", code: "rm", usb_code: 0x0417},
        ROMANIAN___ROMANIA:             {name: "Romanian - Romania", code: "ro", usb_code: 0x0418},
        ROMANIAN___REPUBLIC_OF_MOLDOVA: {name: "Romanian - Republic of Moldova", code: "ro_mo", usb_code: 0x0818},
        RUSSIAN:                        {name: "Russian", code: "ru", usb_code: 0x0419},
        RUSSIAN___REPUBLIC_OF_MOLDOVA:  {name: "Russian - Republic of Moldova", code: "ru_mo", usb_code: 0x0819},
        SANSKRIT:                       {name: "Sanskrit", code: "sa", usb_code: 0x044f},
        SERBIAN___CYRILLIC:             {name: "Serbian - Cyrillic", code: "sr_sp", usb_code: 0x0c1a},
        SERBIAN___LATIN:                {name: "Serbian - Latin", code: "sr_sp", usb_code: 0x081a},
        SETSUANA:                       {name: "Setsuana", code: "tn", usb_code: 0x0432},
        SLOVENIAN:                      {name: "Slovenian", code: "sl", usb_code: 0x0424},
        SLOVAK:                         {name: "Slovak", code: "sk", usb_code: 0x041b},
        SORBIAN:                        {name: "Sorbian", code: "sb", usb_code: 0x042e},
        SPANISH___SPAIN__TRADITIONAL_:  {name: "Spanish - Spain (Traditional)", code: "es_es", usb_code: 0x040a},
        SPANISH___ARGENTINA:            {name: "Spanish - Argentina", code: "es_ar", usb_code: 0x2c0a},
        SPANISH___BOLIVIA:              {name: "Spanish - Bolivia", code: "es_bo", usb_code: 0x400a},
        SPANISH___CHILE:                {name: "Spanish - Chile", code: "es_cl", usb_code: 0x340a},
        SPANISH___COLOMBIA:             {name: "Spanish - Colombia", code: "es_co", usb_code: 0x240a},
        SPANISH___COSTA_RICA:           {name: "Spanish - Costa Rica", code: "es_cr", usb_code: 0x140a},
        SPANISH___DOMINICAN_REPUBLIC:   {name: "Spanish - Dominican Republic", code: "es_do", usb_code: 0x1c0a},
        SPANISH___ECUADOR:              {name: "Spanish - Ecuador", code: "es_ec", usb_code: 0x300a},
        SPANISH___GUATEMALA:            {name: "Spanish - Guatemala", code: "es_gt", usb_code: 0x100a},
        SPANISH___HONDURAS:             {name: "Spanish - Honduras", code: "es_hn", usb_code: 0x480a},
        SPANISH___MEXICO:               {name: "Spanish - Mexico", code: "es_mx", usb_code: 0x080a},
        SPANISH___NICARAGUA:            {name: "Spanish - Nicaragua", code: "es_ni", usb_code: 0x4c0a},
        SPANISH___PANAMA:               {name: "Spanish - Panama", code: "es_pa", usb_code: 0x180a},
        SPANISH___PERU:                 {name: "Spanish - Peru", code: "es_pe", usb_code: 0x280a},
        SPANISH___PUERTO_RICO:          {name: "Spanish - Puerto Rico", code: "es_pr", usb_code: 0x500a},
        SPANISH___PARAGUAY:             {name: "Spanish - Paraguay", code: "es_py", usb_code: 0x3c0a},
        SPANISH___EL_SALVADOR:          {name: "Spanish - El Salvador", code: "es_sv", usb_code: 0x440a},
        SPANISH___URUGUAY:              {name: "Spanish - Uruguay", code: "es_uy", usb_code: 0x380a},
        SPANISH___VENEZUELA:            {name: "Spanish - Venezuela", code: "es_ve", usb_code: 0x200a},
        SOUTHERN_SOTHO:                 {name: "Southern Sotho", code: "st", usb_code: 0x0430},
        SWAHILI:                        {name: "Swahili", code: "sw", usb_code: 0x0441},
        SWEDISH___SWEDEN:               {name: "Swedish - Sweden", code: "sv_se", usb_code: 0x041d},
        SWEDISH___FINLAND:              {name: "Swedish - Finland", code: "sv_fi", usb_code: 0x081d},
        TAMIL:                          {name: "Tamil", code: "ta", usb_code: 0x0449},
        TATAR:                          {name: "Tatar", code: "tt", usb_code: 0x0444},
        THAI:                           {name: "Thai", code: "th", usb_code: 0x041e},
        TURKISH:                        {name: "Turkish", code: "tr", usb_code: 0x041f},
        TSONGA:                         {name: "Tsonga", code: "ts", usb_code: 0x0431},
        UKRAINIAN:                      {name: "Ukrainian", code: "uk", usb_code: 0x0422},
        URDU:                           {name: "Urdu", code: "ur", usb_code: 0x0420},
        UZBEK___CYRILLIC:               {name: "Uzbek - Cyrillic", code: "uz_uz", usb_code: 0x0843},
        UZBEK___LATIN:                  {name: "Uzbek – Latin", code: "uz_uz", usb_code: 0x0443},
        VIETNAMESE:                     {name: "Vietnamese", code: "vi", usb_code: 0x042a},
        XHOSA:                          {name: "Xhosa", code: "xh", usb_code: 0x0434},
        YIDDISH:                        {name: "Yiddish", code: "yi", usb_code: 0x043d},
        ZULU:                           {name: "Zulu", code: "zu", usb_code: 0x0435},
    }.freeze.each{|_,data| data.each{|_,val| val.freeze}; data.freeze}    # make the constant contents constant

    private_constant :KNOWN

    ##
    # Gets a language by key or name.
    def self.[](name)
      get_by_name(name)
    end

    # :nodoc:
    def self.[]=(*args)
      raise 'can\'t modify constants'
    end


    ##
    # Gets a language by name.
    def self.get_by_name(name)
      name_sym = name.to_s.upcase.to_sym
      name = name.to_s.downcase
      if KNOWN.keys.include?(name_sym)
        return KNOWN[name_sym]
      else
        res = KNOWN.find{|k,v| v[:name].downcase == name}
        return res[1] if res && res.length == 2
      end
      nil
    end

    ##
    # Gets a language by code.
    def self.get_by_code(code)
      code = code.to_s.downcase
      res = KNOWN.find{|k,v| v[:code] == code}
      return res[1] if res && res.length == 2
    end

    ##
    # Gets a language by USB code.
    def self.get_by_usb_code(code)
      code = code.to_i
      res = KNOWN.find{|k,v| v[:usb_code] == code}
      return res[1] if res && res.length == 2
    end

    ##
    # Gets a language.
    #
    # The input value can be the name, code, or USB code.
    def self.get(language)
      if language.is_a?(Numeric)
        get_by_usb_code(language)
      elsif language.is_a?(Symbol) || language.is_a?(String)
        get_by_name(language) || get_by_code(language)
      elsif language.is_a?(Hash)
        if language[:usb_code]
          get_by_usb_code(language[:usb_code])
        elsif language[:code]
          get_by_code(language[:code])
        elsif language[:name]
          get_by_name(language[:name])
        else
          nil
        end
      else
        nil
      end
    end

    # :nodoc:
    def self.method_missing(m,*a,&b)
      if KNOWN.respond_to?(m)
        KNOWN.send m, *a, &b
      else
        super m, *a, &b
      end
    end


  end
end