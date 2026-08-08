# Portal components

The portal remains a zero-build Vue 3 application. Component templates are plain HTML files loaded by `component-loader.js` before the root app mounts.

## Structure

- `shared/`: views used by both entry pages.
- `admin/`: the admin shell and one component per navigation section.
- `trainee/`: the trainee shell, profile header, overview, plan builder, and history.

## State contract

`app.js` owns Supabase access and the shared reactive controller. It provides that controller under the `portal` injection key. The loader exposes the same refs, computed values, and actions to every component, so moving markup into a component does not duplicate data loading or change existing handlers.

When adding a component:

1. Add its HTML template in the appropriate folder.
2. Register its tag and path in `component-loader.js`.
3. Use an explicit closing tag in `index.html` or `trainee.html` because browser-parsed custom elements are not self-closing.

Keep data access and mutations in `app.js`; components should remain presentation-focused.
