# SailorBook Design Specifications

## 🎨 Overview
This document defines the comprehensive design specifications for SailorBook, establishing consistent visual standards, interaction patterns, and component behaviors for use with Playwright MCP testing and subagent orchestration.

## 📱 Material 3 Design System

### Core Design Principles
- **Privacy-First**: No user tracking, offline-capable design
- **Accessibility**: WCAG 2.1 AA compliance with semantic structure
- **Cross-Platform**: Consistent experience across mobile, desktop, and web
- **Performance**: <300ms interaction response times

### Color Palette & Theming

#### Light Theme
```dart
// Primary Colors
- Primary: #1976D2 (Material Blue)
- OnPrimary: #FFFFFF
- PrimaryContainer: #BBDEFB
- OnPrimaryContainer: #0D47A1

// Surface Colors  
- Surface: #FAFAFA
- OnSurface: #1C1B1F
- SurfaceVariant: #E7E0EC
- OnSurfaceVariant: #49454F

// Interactive Elements
- Success: #4CAF50
- Warning: #FF9800
- Error: #F44336
- Info: #2196F3
```

#### Dark Theme (Future Implementation)
```dart
- Surface: #1C1B1F
- OnSurface: #E6E1E5
- Primary: #90CAF9
- Error: #F2B8B5
```

### Typography Scale
```dart
// Material 3 Typography
- displayLarge: 57sp, Regular
- displayMedium: 45sp, Regular  
- displaySmall: 36sp, Regular
- headlineLarge: 32sp, Regular
- headlineMedium: 28sp, Regular
- titleLarge: 22sp, Medium (App Bar titles)
- titleMedium: 16sp, Medium (Card titles)
- bodyLarge: 16sp, Regular (Main content)
- bodyMedium: 14sp, Regular (Secondary content)
- labelLarge: 14sp, Medium (Buttons)
```

## 🏗️ Component Architecture

### Navigation Structure
```yaml
app_structure:
  navigation_type: bottom_navigation_bar
  tabs:
    - id: library-tab
      label: Library
      icon: library_books
      test_id: library-tab
    - id: search-tab  
      label: Search
      icon: search
      test_id: search-tab
    - id: player-tab
      label: Player
      icon: play_circle
      test_id: player-tab
```

### Core UI Components

#### 1. Search Interface
```yaml
search_view:
  layout: column
  components:
    - search_field:
        test_id: search-field
        placeholder: "Search for books..."
        type: outlined_text_field
        icon: search
        validation: min_length_3
    - search_results:
        test_id: search-results
        layout: list_view
        scroll: vertical
        items: book_cards
```

#### 2. Book Card Component
```yaml
book_card:
  test_id_pattern: book-card-{book_id}
  layout: card
  elevation: 1
  margin: 8px
  components:
    - cover_image:
        size: 80x120px
        fallback: book_icon
        border_radius: 8px
    - book_info:
        title:
          style: titleMedium
          max_lines: 2
          overflow: ellipsis
        author:
          style: bodyMedium
          color: onSurfaceVariant
        metadata:
          size: "X.X MB"
          style: labelSmall
    - action_button:
        test_id: download-btn-{book_id}
        type: filled_button
        states: [download, downloading, downloaded]
```

#### 3. Book Details View
```yaml
book_details:
  layout: column
  scroll: vertical
  components:
    - header:
        cover_image: 160x240px
        title: headlineMedium
        author: titleMedium
        metadata: bodyMedium
    - download_section:
        download_button:
          test_id: download-book-btn
          type: filled_button
          states: [download, downloading, downloaded]
        progress_bar:
          test_id: download-progress
          visibility: conditional
        status_text:
          test_id: download-status-text
          type: body_medium
    - success_card:
        test_id: download-success-text
        type: success_card
        visibility: on_success
        content: user_guidance
    - error_card:
        test_id: download-error-text
        type: error_card
        visibility: on_error
        selectable: true
```

#### 4. Library View
```yaml
library_view:
  test_id: library-view
  layout: grid_view
  cross_axis_count: responsive
  components:
    - empty_state:
        test_id: library-empty-state
        visibility: when_no_books
        content: "No books downloaded yet"
    - book_grid:
        test_id_pattern: library-book-{book_id}
        item_component: book_card
        actions: [open, delete]
```

#### 5. Player Interface
```yaml
player_view:
  test_id: player-view
  layout: column
  components:
    - now_playing:
        book_cover: 200x300px
        title: titleLarge
        author: titleMedium
        chapter: bodyMedium
    - progress_section:
        progress_bar:
          test_id: audio-progress
          type: linear_progress
        time_display:
          current: "0:00"
          total: "0:00"
    - controls:
        test_id: player-controls
        layout: row
        buttons:
          - previous: skip_previous
          - play_pause: play_arrow / pause
          - next: skip_next
          - speed: speed_control
```

## 🎯 Test Identification Strategy

### Test ID Naming Convention
```yaml
naming_patterns:
  views: "{view_name}-view"           # library-view
  tabs: "{tab_name}-tab"              # search-tab
  buttons: "{action}-btn"             # download-btn
  fields: "{purpose}-field"           # search-field
  lists: "{content}-results"          # search-results
  cards: "{type}-card-{id}"          # book-card-123
  status: "{action}-{type}-text"      # download-success-text
```

### State-Based Testing
```yaml
component_states:
  download_button:
    idle: "Download"
    loading: "Downloading..."  
    success: "Downloaded"
    error: "Retry Download"
  search_field:
    empty: placeholder_visible
    typing: text_input_active
    results: results_populated
  library:
    empty: empty_state_visible
    populated: book_grid_visible
```

## 🔧 Interaction Specifications

### Touch Targets & Accessibility
```yaml
touch_targets:
  minimum_size: 44x44px
  recommended_size: 48x48px
  spacing: 8px_minimum

accessibility:
  semantic_labels: required
  focus_management: keyboard_navigation
  screen_reader: full_support
  color_contrast: 4.5:1_minimum
```

### Animation Specifications
```yaml
animations:
  page_transitions: 300ms_ease_in_out
  button_feedback: 150ms_scale_transform
  loading_states: circular_progress_indicator
  success_feedback: 200ms_color_transition
```

## 📊 Responsive Design Breakpoints

### Viewport Specifications
```yaml
breakpoints:
  mobile: 0-599px
    navigation: bottom_tabs
    grid_columns: 2
    padding: 16px
    
  tablet: 600-1023px  
    navigation: bottom_tabs
    grid_columns: 3
    padding: 24px
    
  desktop: 1024px+
    navigation: navigation_rail_optional
    grid_columns: 4-6
    padding: 32px
```

### Platform-Specific Adaptations
```yaml
platform_adaptations:
  web:
    scroll_behavior: smooth
    context_menus: disabled
    text_selection: enabled_for_errors
    downloads: browser_native
    
  mobile:
    haptic_feedback: enabled
    safe_area: respected
    orientation: portrait_primary
    
  desktop:
    keyboard_shortcuts: enabled
    window_chrome: system_default
    file_system: native_access
```

## 🎮 Interaction Patterns

### Navigation Flow
```yaml
navigation_flow:
  entry_point: library_tab
  search_flow:
    - library_tab → search_tab
    - search_field → type_query → enter
    - search_results → select_book
    - book_details → download_action
    - success_message → return_to_library
    
  library_flow:
    - library_tab → view_downloaded_books
    - select_book → book_details → open_player
    - player_view → playback_controls
```

### Error Handling Patterns
```yaml
error_handling:
  display_location: contextual_to_action
  message_format: user_friendly_guidance
  action_buttons: retry_or_cancel
  error_persistence: dismissible_manually
  
  success_feedback:
    download_complete: success_card_with_guidance
    search_complete: results_count_display
    action_complete: brief_status_message
```

## 🧪 Testing Specifications

### Critical User Journeys
```yaml
critical_paths:
  1. search_and_download:
      description: "User searches for and downloads a book"
      steps: [navigate_search, enter_query, select_result, initiate_download, verify_success]
      
  2. library_management:
      description: "User manages their downloaded books"
      steps: [view_library, select_book, access_details, manage_book]
      
  3. reading_experience:
      description: "User plays and controls book audio"
      steps: [open_book, start_playback, control_audio, navigate_chapters]
```

### Performance Specifications
```yaml
performance_targets:
  page_load: <3000ms
  search_response: <2000ms
  download_initiation: <500ms
  ui_interaction: <300ms
  
  memory_usage:
    baseline: <100MB
    with_audio: <300MB
    maximum: <512MB
```

## 🔍 MCP Testing Integration Points

### Element Detection Strategy
```yaml
mcp_selectors:
  primary_strategy: test_id_attributes
  fallback_strategy: semantic_roles
  last_resort: css_selectors
  
  test_id_format: "data-testid='{test-id}'"
  accessibility_format: "role='{role}' name='{name}'"
```

### Natural Language Test Descriptions
```yaml
test_scenarios:
  search_functionality:
    - "When I search for 'alice wonderland', I should see relevant results"
    - "Clicking on a search result should open book details"
    - "The download button should be clearly visible and accessible"
    
  download_workflow:
    - "When I click download, it should handle CORS gracefully"
    - "Download progress should be visible during the process"
    - "Success message should provide clear next steps"
    
  error_scenarios:
    - "Invalid searches should show helpful guidance"
    - "Network errors should provide retry options"
    - "Browser restrictions should explain alternative approaches"
```

## 📋 Validation Checklist

### Design Compliance
- [ ] All interactive elements have 48x48px minimum touch targets
- [ ] Color contrast meets WCAG 2.1 AA standards (4.5:1)
- [ ] Typography follows Material 3 scale
- [ ] Animations respect reduced motion preferences
- [ ] Focus indicators are clearly visible

### Test Readiness
- [ ] All interactive elements have unique test IDs
- [ ] Error states are properly identified
- [ ] Loading states have appropriate indicators
- [ ] Success feedback is clearly marked
- [ ] Navigation paths are testable

### Cross-Platform Compatibility
- [ ] Responsive breakpoints function correctly
- [ ] Platform-specific adaptations work as intended
- [ ] Touch and mouse interactions both supported
- [ ] Keyboard navigation fully functional
- [ ] Screen readers can navigate effectively

---

**Last Updated**: 2025-08-31  
**Version**: 1.0.0  
**Status**: Active - Ready for MCP Playwright Integration

*This specification serves as the definitive guide for automated testing with Playwright MCP and ensures consistent design implementation across the SailorBook application.*