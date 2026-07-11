using System;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;

namespace MarkKitWin
{
    public partial class MainWindow : Window
    {
        private MarkdownSyntaxHighlighter _highlighter;
        private string? _currentFilePath = null;

        public MainWindow()
        {
            InitializeComponent();
            _highlighter = new MarkdownSyntaxHighlighter(Editor);
            _highlighter.HighlightAll();
            
            // Allow drag and drop files
            AllowDrop = true;
            Drop += MainWindow_Drop;
        }

        private void Editor_TextChanged(object sender, TextChangedEventArgs e)
        {
            _highlighter?.TextDidChange(e);
        }

        private void Editor_SelectionChanged(object sender, RoutedEventArgs e)
        {
            _highlighter?.SelectionDidChange();
        }

        private void Editor_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
            {
                if (_highlighter?.HandleEnterKey() == true)
                {
                    e.Handled = true;
                }
            }
            
            // Handle Save
            if (e.Key == Key.S && Keyboard.Modifiers == ModifierKeys.Control)
            {
                SaveFile();
                e.Handled = true;
            }
        }

        private void Setting_Changed(object sender, RoutedEventArgs e)
        {
            if (_highlighter == null) return;
            
            _highlighter.HideLinks = MenuHideLinks.IsChecked;
            // MenuClickableLinks and MenuInlineImages can be passed to highlighter if implemented
            _highlighter.DynamicListIndentBullets = MenuDynamicBullets.IsChecked;
            _highlighter.DynamicListIndentNumbers = MenuDynamicNumbers.IsChecked;
            
            _highlighter.HighlightAll();
        }

        private void MenuOpen_Click(object sender, RoutedEventArgs e)
        {
            Microsoft.Win32.OpenFileDialog dlg = new Microsoft.Win32.OpenFileDialog();
            dlg.Filter = "Markdown documents (.md)|*.md|Text documents (.txt)|*.txt|All files (*.*)|*.*";
            if (dlg.ShowDialog() == true)
            {
                OpenFile(dlg.FileName);
            }
        }

        private void MenuSave_Click(object sender, RoutedEventArgs e)
        {
            SaveFile();
        }

        private void MenuSaveAs_Click(object sender, RoutedEventArgs e)
        {
            _currentFilePath = null;
            SaveFile();
        }

        private void MenuExit_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }

        private void SettingFont_Click(object sender, RoutedEventArgs e)
        {
            if (sender is MenuItem menuItem)
            {
                foreach (MenuItem item in MenuFont.Items) item.IsChecked = false;
                menuItem.IsChecked = true;
                _highlighter?.ChangeFont(menuItem.Header?.ToString() ?? "Segoe UI");
            }
        }

        private void SettingFontSize_Click(object sender, RoutedEventArgs e)
        {
            if (sender is MenuItem menuItem && double.TryParse(menuItem.Header?.ToString(), out double size))
            {
                foreach (MenuItem item in MenuFontSize.Items) item.IsChecked = false;
                menuItem.IsChecked = true;
                _highlighter?.ChangeFontSize(size);
            }
        }

        private void SettingTheme_Click(object sender, RoutedEventArgs e)
        {
            if (sender is MenuItem menuItem)
            {
                foreach (MenuItem item in MenuTheme.Items) item.IsChecked = false;
                menuItem.IsChecked = true;
                
                string theme = menuItem.Header?.ToString() ?? "Light";
                if (theme == "Dark")
                {
                    Editor.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 30, 30));
                    Editor.Foreground = System.Windows.Media.Brushes.White;
                    _highlighter?.ChangeTheme(true);
                }
                else
                {
                    Editor.Background = System.Windows.Media.Brushes.White;
                    Editor.Foreground = System.Windows.Media.Brushes.Black;
                    _highlighter?.ChangeTheme(false);
                }
            }
        }

        private void MainWindow_Drop(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
                if (files != null && files.Length > 0)
                {
                    OpenFile(files[0]);
                }
            }
        }

        private void OpenFile(string path)
        {
            try
            {
                string content = File.ReadAllText(path);
                _currentFilePath = path;
                Title = $"MarkKit - {Path.GetFileName(path)}";
                
                Editor.Document.Blocks.Clear();
                Editor.Document.Blocks.Add(new Paragraph(new System.Windows.Documents.Run(content)));
                _highlighter.HighlightAll();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error opening file: {ex.Message}");
            }
        }

        private void SaveFile()
        {
            if (_currentFilePath == null)
            {
                Microsoft.Win32.SaveFileDialog dlg = new Microsoft.Win32.SaveFileDialog();
                dlg.FileName = "Document"; // Default file name
                dlg.DefaultExt = ".md"; // Default file extension
                dlg.Filter = "Markdown documents (.md)|*.md|Text documents (.txt)|*.txt|All files (*.*)|*.*"; 

                bool? result = dlg.ShowDialog();

                if (result == true)
                {
                    _currentFilePath = dlg.FileName;
                    Title = $"MarkKit - {Path.GetFileName(_currentFilePath)}";
                }
                else
                {
                    return;
                }
            }

            try
            {
                string text = new System.Windows.Documents.TextRange(Editor.Document.ContentStart, Editor.Document.ContentEnd).Text;
                // RichTextBox adds an extra newline at the end
                if (text.EndsWith("\r\n")) text = text.Substring(0, text.Length - 2);
                else if (text.EndsWith("\n")) text = text.Substring(0, text.Length - 1);
                
                File.WriteAllText(_currentFilePath, text);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving file: {ex.Message}");
            }
        }
    }
}