eyeneko_sources = [
  icons,
  'main.vala',
  'application.vala',
  'window.vala',
  'gst.vala',
  'pipetap_proxy.vala',
  'auto_focus.vala',
  'logic/color_correction_filter.vala',
  'logic/filter.vala',
  'logic/helpers.vala',
  'elements/bin_base.vala',
  'elements/downscale.vala',
  'elements/focus_analyze.vala',
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
]

blueprints = custom_target(
  'blueprints',
  input: files(
    'gtk/help-overlay.blp',
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
