using System;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Threading;

namespace MarkKitWin
{
    public class MarkdownSyntaxHighlighter
    {
        private RichTextBox _editor;
        private bool _isHighlighting = false;
        
        private double _baseFontSize = 16.0;
        private FontFamily _baseFontFamily = new FontFamily("Segoe UI");
        private FontFamily _codeFontFamily = new FontFamily("Consolas");

        public bool HideLinks { get; set; } = true;
        public bool DynamicListIndentBullets { get; set; } = true;
        public bool DynamicListIndentNumbers { get; set; } = true;
        
        private bool _isDarkTheme = false;
        private bool _highlightPending = false;

        // Precompiled regexes — compiled once, reused every keystroke
        private static readonly RegexOptions _opts = RegexOptions.Multiline | RegexOptions.Compiled;
        private static readonly Regex _rxH6 = new(@"^###### .+$", _opts);
        private static readonly Regex _rxH5 = new(@"^##### .+$", _opts);
        private static readonly Regex _rxH4 = new(@"^#### .+$", _opts);
        private static readonly Regex _rxH3 = new(@"^### .+$", _opts);
        private static readonly Regex _rxH2 = new(@"^## .+$", _opts);
        private static readonly Regex _rxH1 = new(@"^# .+$", _opts);
        private static readonly Regex _rxBold = new(@"(?:\*\*|__)[^*_]+(?:\*\*|__)", _opts);
        private static readonly Regex _rxItalic = new(@"(?<!\*)\*(?!\*)[^*]+\*(?!\*)|(?<!_)_(?!_)[^_]+_(?!_)", _opts);
        private static readonly Regex _rxStrike = new(@"~~[^~]+~~", _opts);
        private static readonly Regex _rxCode = new(@"`[^`\n]+`", _opts);
        private static readonly Regex _rxBlockquote = new(@"^> .+$", _opts);
        private static readonly Regex _rxList = new(@"^[ \t]*[-*+] ", _opts);
        private static readonly Regex _rxLink = new(@"!?\[([^\]]+)\]\(([^)]+)\)", _opts);

        // Cached brush for code background (avoid creating every highlight)
        private static readonly SolidColorBrush _codeBackground = new(Color.FromArgb(50, 128, 128, 128));

        static MarkdownSyntaxHighlighter()
        {
            _codeBackground.Freeze(); // Frozen brushes skip thread checks — faster
        }

        public MarkdownSyntaxHighlighter(RichTextBox editor)
        {
            _editor = editor;
        }

        public void ChangeFont(string fontName)
        {
            _baseFontFamily = new FontFamily(fontName);
            HighlightAll();
        }

        public void ChangeFontSize(double size)
        {
            _baseFontSize = size;
            HighlightAll();
        }

        public void ChangeTheme(bool isDark)
        {
            _isDarkTheme = isDark;
            HighlightAll();
        }

        public void HighlightAll()
        {
            if (_editor.Document == null) return;
            TextRange fullRange = new TextRange(_editor.Document.ContentStart, _editor.Document.ContentEnd);
            HighlightRange(fullRange);
        }

        public void TextDidChange(TextChangedEventArgs e)
        {
            if (_isHighlighting) return;
            ScheduleHighlight();
        }

        private void ScheduleHighlight()
        {
            if (_highlightPending) return;
            _highlightPending = true;
            _editor.Dispatcher.BeginInvoke(DispatcherPriority.ApplicationIdle, new Action(() =>
            {
                _highlightPending = false;
                HighlightAll();
            }));
        }

        public void SelectionDidChange()
        {
            if (_isHighlighting) return;
            UpdateLinkVisibility();
        }

        private void UpdateLinkVisibility()
        {
            if (_isHighlighting || _editor.Document == null) return;
            _isHighlighting = true;
            _editor.TextChanged -= Editor_TextChanged;
            _editor.BeginChange();
            try
            {
                int startIdx = GetTextOffset(_editor.Selection.Start);
                int endIdx = GetTextOffset(_editor.Selection.End);
                
                TextRange fullRange = new TextRange(_editor.Document.ContentStart, _editor.Document.ContentEnd);
                string text = fullRange.Text;

                foreach (Match m in _rxLink.Matches(text))
                {
                    bool isIntersecting = !(endIdx < m.Index || startIdx > m.Index + m.Length);
                    
                    Group urlGroup = m.Groups[2];
                    if (urlGroup.Success)
                    {
                        TextPointer? urlStart = GetPointerAtTextOffset(urlGroup.Index - 1);
                        TextPointer? urlEnd = GetPointerAtTextOffset(urlGroup.Index + urlGroup.Length + 1);
                        if (urlStart != null && urlEnd != null)
                        {
                            TextRange urlRange = new TextRange(urlStart, urlEnd);
                            if (HideLinks && !isIntersecting)
                            {
                                urlRange.ApplyPropertyValue(TextElement.FontSizeProperty, 0.1);
                                urlRange.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.Transparent);
                            }
                            else
                            {
                                urlRange.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize);
                                urlRange.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.DodgerBlue);
                            }
                        }
                    }
                }
            }
            finally
            {
                _editor.EndChange();
                _editor.TextChanged += Editor_TextChanged;
                _isHighlighting = false;
            }
        }

        public bool HandleEnterKey()
        {
            TextPointer caret = _editor.CaretPosition;
            TextRange lineRange = new TextRange(caret.GetLineStartPosition(0) ?? caret, caret);
            string textBeforeCursor = lineRange.Text;

            string pattern = "";
            if (DynamicListIndentBullets && DynamicListIndentNumbers)
            {
                pattern = @"^([ \t]*)([-*+]|\d+\.)[ \t]+(.*)$";
            }
            else if (DynamicListIndentBullets)
            {
                pattern = @"^([ \t]*)([-*+])[ \t]+(.*)$";
            }
            else if (DynamicListIndentNumbers)
            {
                pattern = @"^([ \t]*)(\d+\.)[ \t]+(.*)$";
            }

            if (string.IsNullOrEmpty(pattern)) return false;

            Match match = Regex.Match(textBeforeCursor, pattern);

            if (match.Success)
            {
                string indent = match.Groups[1].Value;
                string bullet = match.Groups[2].Value;
                string content = match.Groups[3].Value;

                if (string.IsNullOrWhiteSpace(content))
                {
                    lineRange.Text = "";
                    return false;
                }
                else
                {
                    string nextBullet = bullet;
                    if (char.IsDigit(bullet[0]))
                    {
                        if (int.TryParse(bullet.Substring(0, bullet.Length - 1), out int num))
                        {
                            nextBullet = $"{num + 1}.";
                        }
                    }

                    string insertion = $"\n{indent}{nextBullet} ";
                    caret.InsertTextInRun(insertion);
                    
                    TextPointer newCaret = caret.GetPositionAtOffset(insertion.Length, LogicalDirection.Forward);
                    if (newCaret != null)
                    {
                        _editor.CaretPosition = newCaret;
                    }
                    return true;
                }
            }

            return false;
        }

        private void HighlightRange(TextRange range)
        {
            if (_isHighlighting) return;
            _isHighlighting = true;

            int caretTextOffset = GetTextOffset(_editor.CaretPosition);
            int selStartTextOffset = GetTextOffset(_editor.Selection.Start);
            int selEndTextOffset = GetTextOffset(_editor.Selection.End);

            _editor.TextChanged -= Editor_TextChanged;
            _editor.BeginChange();

            try
            {
                range.ClearAllProperties();
                range.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize);
                range.ApplyPropertyValue(TextElement.FontFamilyProperty, _baseFontFamily);
                range.ApplyPropertyValue(TextElement.ForegroundProperty, _isDarkTheme ? Brushes.White : Brushes.Black);
                range.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Normal);
                range.ApplyPropertyValue(TextElement.FontStyleProperty, FontStyles.Normal);

                string text = range.Text;

                // Helper using precompiled regex
                void ApplyFormatting(Regex rx, Action<TextRange, Match> applyAction)
                {
                    foreach (Match m in rx.Matches(text))
                    {
                        TextPointer? start = GetPointerAtTextOffset(m.Index);
                        TextPointer? end = GetPointerAtTextOffset(m.Index + m.Length);
                        if (start != null && end != null)
                        {
                            TextRange matchRange = new TextRange(start, end);
                            applyAction(matchRange, m);
                        }
                    }
                }

                // Headers (longest prefix first)
                ApplyFormatting(_rxH6, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 0.85); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });
                ApplyFormatting(_rxH5, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 1.0); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });
                ApplyFormatting(_rxH4, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 1.15); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });
                ApplyFormatting(_rxH3, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 1.25); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });
                ApplyFormatting(_rxH2, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 1.5); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });
                ApplyFormatting(_rxH1, (r, m) => { r.ApplyPropertyValue(TextElement.FontSizeProperty, _baseFontSize * 2.0); r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold); });

                ApplyFormatting(_rxBold, (r, m) => r.ApplyPropertyValue(TextElement.FontWeightProperty, FontWeights.Bold));
                ApplyFormatting(_rxItalic, (r, m) => r.ApplyPropertyValue(TextElement.FontStyleProperty, FontStyles.Italic));
                ApplyFormatting(_rxStrike, (r, m) => r.ApplyPropertyValue(Inline.TextDecorationsProperty, TextDecorations.Strikethrough));

                ApplyFormatting(_rxCode, (r, m) => {
                    r.ApplyPropertyValue(TextElement.FontFamilyProperty, _codeFontFamily);
                    r.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.Crimson);
                    r.ApplyPropertyValue(TextElement.BackgroundProperty, _codeBackground);
                });

                ApplyFormatting(_rxBlockquote, (r, m) => {
                    r.ApplyPropertyValue(TextElement.FontStyleProperty, FontStyles.Italic);
                    r.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.Gray);
                });

                ApplyFormatting(_rxList, (r, m) => r.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.Gray));

                // Links
                ApplyFormatting(_rxLink, (r, m) => {
                    r.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.DodgerBlue);
                    
                    bool isIntersecting = !(selEndTextOffset < m.Index || selStartTextOffset > m.Index + m.Length);
                    
                    if (HideLinks && !isIntersecting)
                    {
                        Group urlGroup = m.Groups[2];
                        if (urlGroup.Success)
                        {
                            TextPointer? urlStart = GetPointerAtTextOffset(urlGroup.Index - 1);
                            TextPointer? urlEnd = GetPointerAtTextOffset(urlGroup.Index + urlGroup.Length + 1);
                            if (urlStart != null && urlEnd != null)
                            {
                                TextRange urlRange = new TextRange(urlStart, urlEnd);
                                urlRange.ApplyPropertyValue(TextElement.FontSizeProperty, 0.1);
                                urlRange.ApplyPropertyValue(TextElement.ForegroundProperty, Brushes.Transparent);
                            }
                        }
                    }
                });
            }
            finally
            {
                TextPointer? newCaret = GetPointerAtTextOffset(caretTextOffset);
                if (newCaret != null)
                {
                    _editor.CaretPosition = newCaret;
                }

                if (selStartTextOffset != selEndTextOffset)
                {
                    TextPointer? newStart = GetPointerAtTextOffset(selStartTextOffset);
                    TextPointer? newEnd = GetPointerAtTextOffset(selEndTextOffset);
                    if (newStart != null && newEnd != null)
                    {
                        _editor.Selection.Select(newStart, newEnd);
                    }
                }

                _editor.EndChange();
                _editor.TextChanged += Editor_TextChanged;
                _isHighlighting = false;
            }
        }

        private int GetTextOffset(TextPointer pointer)
        {
            TextRange range = new TextRange(_editor.Document.ContentStart, pointer);
            return range.Text.Length;
        }

        private TextPointer? GetPointerAtTextOffset(int targetOffset)
        {
            if (targetOffset <= 0) return _editor.Document.ContentStart;

            TextPointer current = _editor.Document.ContentStart;
            int consumed = 0;

            while (current != null)
            {
                TextPointerContext ctx = current.GetPointerContext(LogicalDirection.Forward);

                if (ctx == TextPointerContext.Text)
                {
                    string run = current.GetTextInRun(LogicalDirection.Forward);
                    if (consumed + run.Length >= targetOffset)
                    {
                        int into = targetOffset - consumed;
                        return current.GetPositionAtOffset(into, LogicalDirection.Forward);
                    }
                    consumed += run.Length;
                }
                else if (ctx == TextPointerContext.ElementEnd)
                {
                    DependencyObject element = current.GetAdjacentElement(LogicalDirection.Forward);
                    if (element is Paragraph || element is LineBreak)
                    {
                        if (consumed + 2 > targetOffset)
                        {
                            return current;
                        }
                        consumed += 2;
                    }
                }

                current = current.GetNextContextPosition(LogicalDirection.Forward);
            }

            return _editor.Document.ContentEnd;
        }

        private void Editor_TextChanged(object sender, TextChangedEventArgs e)
        {
            TextDidChange(e);
        }
    }
}
