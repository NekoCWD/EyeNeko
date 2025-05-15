eyeneko_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

eyeneko_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
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
