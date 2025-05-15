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

eyeneko_sources += gnome.compile_resources(
  'eyeneko-resources',
  'eyeneko.gresource.xml',
  c_name: 'eyeneko',
)

executable(
  'eyeneko',
  eyeneko_sources,
  dependencies: eyeneko_deps,
  include_directories: config_inc,
  install: true,
)
