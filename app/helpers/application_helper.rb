module ApplicationHelper
  include SanitizeUrl

  def html_lang
    I18n.locale.to_s
  end

  def sanitize_url(url)
    if !url.nil?
      super(url, schemes: ['http', 'https'], replace_evil_with: root_url)
    end
  end

  def flash_class(level, sticky: false, fixed: false)
    class_names = []

    case level
    when 'notice'
      class_names << 'alert-success'
    when 'alert', 'error'
      class_names << 'alert-danger'
    end

    if sticky
      class_names << 'sticky'
    end
    if fixed
      class_names << 'alert-fixed'
    end
    class_names.join(' ')
  end

  def flash_role(level)
    return "status" if level == "notice"

    'alert'
  end

  def react_component(name, props = {}, html = {})
    tag.div(**html.merge(data: { controller: 'react', react_component_value: name, react_props_value: props.to_json }))
  end

  def render_to_element(selector, partial:, outer: false, locals: {})
    method = outer ? 'outerHTML' : 'innerHTML'
    html = escape_javascript(render partial: partial, locals: locals)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').#{method} = \"#{html}\";")
    # rubocop:enable Rails/OutputSafety
  end

  def append_to_element(selector, partial:, locals: {})
    html = escape_javascript(render partial: partial, locals: locals)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').insertAdjacentHTML('beforeend', \"#{html}\");")
    # rubocop:enable Rails/OutputSafety
  end

  def render_flash(timeout: false, sticky: false, fixed: false)
    if flash.any?
      html = render_to_element('#flash_messages', partial: 'layouts/flash_messages', locals: { sticky: sticky, fixed: fixed }, outer: true)
      flash.clear
      if timeout
        html += remove_element('#flash_messages', timeout: timeout, inner: true)
      end
      html
    end
  end

  def remove_element(selector, timeout: 0, inner: false)
    script = "(function() {";
    script << "var el = document.querySelector('#{selector}');"
    method = (inner ? "el.innerHTML = ''" : "el.parentNode.removeChild(el)")
    if timeout.present? && timeout > 0
      script << "if (el) { setTimeout(function() { #{method}; }, #{timeout}); }"
    else
      script << "if (el) { #{method} };"
    end
    script << "})();"
    # rubocop:disable Rails/OutputSafety
    raw(script);
    # rubocop:enable Rails/OutputSafety
  end

  def show_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').classList.remove('hidden');")
    # rubocop:enable Rails/OutputSafety
  end

  def focus_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').focus();")
    # rubocop:enable Rails/OutputSafety
  end

  def disable_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').disabled = true;")
    # rubocop:enable Rails/OutputSafety
  end

  def enable_element(selector)
    # rubocop:disable Rails/OutputSafety
    raw("document.querySelector('#{selector}').disabled = false;")
    # rubocop:enable Rails/OutputSafety
  end

  def fire_event(event_name, data)
    # rubocop:disable Rails/OutputSafety
    raw("DS.fire('#{event_name}', #{raw(data)});")
    # rubocop:enable Rails/OutputSafety
  end

  def current_email
    current_user&.email ||
      current_instructeur&.email ||
      current_administrateur&.email
  end

  def staging?
    Rails.application.config.ds_env == 'staging'
  end

  def contact_link(title, options = {})
    tags, type, dossier_id = options.values_at(:tags, :type, :dossier_id)
    options.except!(:tags, :type, :dossier_id)

    params = { tags: tags, type: type, dossier_id: dossier_id }.compact
    link_to title, contact_url(params), options
  end

  def root_path_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :instructeur
      instructeur_procedures_path
    when :user
      dossiers_path
    else
      root_path
    end
  end

  def root_path_info_for_profile(nav_bar_profile)
    case nav_bar_profile
    when :administrateur
      [admin_procedures_path, "Aller au panneau d’administration"]
    when :instructeur
      [instructeur_procedures_path, 'Aller à la liste des démarches']
    when :user
      [dossiers_path, 'Aller à la liste des dossiers']
    else
      [root_path, "Aller à la page d’accueil"]
    end
  end

  def try_format_date(date)
    date.present? ? I18n.l(date, format: :long) : ''
  end

  def try_format_datetime(datetime)
    datetime.present? ? I18n.l(datetime) : ''
  end

  def try_format_mois_effectif(etablissement)
    if etablissement.entreprise_effectif_mois.present? && etablissement.entreprise_effectif_annee.present?
      [etablissement.entreprise_effectif_mois, etablissement.entreprise_effectif_annee].join('/')
    else
      ''
    end
  end

  def dismiss_outdated_browser_banner
    cookies[:dismissed_outdated_browser_banner] = {
      value: 'true',
      expires: 1.week.from_now
    }
  end

  def has_dismissed_outdated_browser_banner?
    cookies[:dismissed_outdated_browser_banner] == 'true'
  end

  def supported_browser?
    BrowserSupport.supported?(browser)
  end

  def show_outdated_browser_banner?
    !supported_browser? && !has_dismissed_outdated_browser_banner?
  end

  def vite_legacy?
    if ENV['VITE_LEGACY'] == 'disabled'
      false
    else
      Rails.env.production? || ENV['VITE_LEGACY'] == 'enabled'
    end
  end

  def external_link_attributes
    { target: "_blank", rel: "noopener noreferrer" }
  end
end
