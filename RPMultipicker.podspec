Pod::Spec.new do |s|
    s.name     = 'RPMultiPicker'
    s.version  = '1.0.0'
    s.license  = 'MIT'
    s.summary  = 'ImagePicker Whatsapp like.'
    s.homepage = 'https://github.com/MatiMil/RPMultipleImagePicker.git'
    s.social_media_url = ''
    s.authors  = { 'Matijas Milos' => 'matijas.milos@gmx.de' }
    s.source   = { :git => 'https://github.com/MatiMil/RPMultipleImagePicker.git' }
    s.requires_arc = true

    s.ios.deployment_target = '6.0'

    s.public_header_files = 'RPMultiPicker/Classes/*.h'
    s.source_files = 'RPMultiPicker/Classes/*.{h,m}'
    s.resource = "RPMultiPicker/Classes/RPMultipleImagePicker.xib"

    end
