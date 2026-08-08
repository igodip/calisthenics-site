const sharedComponents = {
  'auth-view': './components/shared/auth-view.html',
};

const adminComponents = {
  'admin-sidebar': './components/admin/sidebar.html',
  'admin-topbar': './components/admin/topbar.html',
  'dashboard-section': './components/admin/dashboard-section.html',
  'feedback-section': './components/admin/feedback-section.html',
  'trainees-section': './components/admin/trainees-section.html',
  'trainers-section': './components/admin/trainers-section.html',
  'payments-section': './components/admin/payments-section.html',
  'exercises-section': './components/admin/exercises-section.html',
  'terminology-section': './components/admin/terminology-section.html',
};

const traineeComponents = {
  'trainee-sidebar': './components/trainee/sidebar.html',
  'trainee-topbar': './components/trainee/topbar.html',
  'trainee-profile-header': './components/trainee/profile-header.html',
  'trainee-overview': './components/trainee/overview.html',
  'trainee-plan-builder': './components/trainee/plan-builder.html',
  'trainee-history': './components/trainee/history.html',
};

function createPortalComponent(template) {
  return {
    template,
    setup() {
      const portal = Vue.inject('portal');
      if (!portal) {
        throw new Error('Portal context is unavailable.');
      }
      return { ...portal };
    },
  };
}

async function fetchTemplate(path) {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Unable to load component template: ${path}`);
  }
  return response.text();
}

export async function registerPortalComponents(app, { isTraineeDetailPage }) {
  const componentMap = {
    ...sharedComponents,
    ...(isTraineeDetailPage ? traineeComponents : adminComponents),
  };
  const templates = await Promise.all(
    Object.entries(componentMap).map(async ([name, path]) => [name, await fetchTemplate(path)]),
  );
  templates.forEach(([name, template]) => {
    app.component(name, createPortalComponent(template));
  });
}
