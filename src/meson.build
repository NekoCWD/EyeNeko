eyeneko_sources = [
  icons,
  'main.vala',
  'application.vala',
  'window.vala',
  'gst.vala',
  'logic/helpers.vala',
  'elements/bin_base.vala',
  'elements/camerasrc.vala',
  'elements/downscale.vala',
  'elements/gl_filter.vala',
  'elements/color_correction_matrix.vala',
  'elements/qr_scaner.vala',
  'ui/preferences.vala',
  'ui/caps-row.vala',
  'ui/qr-row.vala',
  'logic/friendly-caps.vala',
]

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
eyeneko_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('gstreamer-1.0'),
  #  dependency('gstreamer-pbutils-1.0'),
  dependency('gstreamer-pbutils-1.0'),
  valac.find_library('encoding-profile-helper', dirs: vapi_dir),
  dependency('zbar'),
  dependency('gee-0.8'),
]

blueprints = custom_target(
  'blueprints',
  input: files(
    'gtk/help-overlay.blp',
    'ui/caps-row.blp',
    'ui/qr-row.blp',
    'window.blp',
  ),
  output: '.',
  command: [
    find_program('blueprint-compiler'),
    'batch-compile',
    '@OUTPUT@',
    '@CURRENT_SOURCE_DIR@',
    '@INPUT@',
  ],
)

eyeneko_sources += gnome.compile_resources(
  'eyeneko-resources',
  'eyeneko.gresource.xml',
  c_name: 'eyeneko',
  dependencies: blueprints,
)

executable(
  'eyeneko',
  eyeneko_sources,
  dependencies: eyeneko_deps,
  include_directories: config_inc,
  install: true,
)
