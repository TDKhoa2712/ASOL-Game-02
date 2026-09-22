"""
Script tạo file Word Báo cáo Ý tưởng và Thiết kế Game (GDD)
Dự án: Vườn Mèo (Working Title)
Đơn vị: Alpaca Solution
"""

import os
import sys

# Ensure UTF-8 output on Windows console
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

# Bảng màu chuẩn thiết kế tài liệu
COLOR_PRIMARY_HEX = "1E3A8A"      # Deep Royal Navy
COLOR_SECONDARY_HEX = "0F766E"    # Deep Teal
COLOR_ACCENT_HEX = "C2410C"       # Warm Amber/Coral
COLOR_DARK_TEXT_HEX = "1E293B"    # Slate 800
COLOR_MUTED_TEXT_HEX = "64748B"   # Slate 500
COLOR_LIGHT_BG_HEX = "F8FAFC"     # Slate 50
COLOR_ALT_ROW_HEX = "F1F5F9"      # Slate 100
COLOR_BORDER_HEX = "CBD5E1"       # Slate 300
COLOR_CALLOUT_BG = "F0FDFA"       # Mint 50
COLOR_CALLOUT_BORDER = "0D9488"   # Teal 600

COLOR_PRIMARY = RGBColor(0x1E, 0x3A, 0x8A)
COLOR_SECONDARY = RGBColor(0x0F, 0x76, 0x6E)
COLOR_ACCENT = RGBColor(0xC2, 0x41, 0x0C)
COLOR_DARK_TEXT = RGBColor(0x1E, 0x29, 0x3B)
COLOR_MUTED_TEXT = RGBColor(0x64, 0x74, 0x8B)

FONT_FAMILY = "Segoe UI"

def set_cell_background(cell, hex_color):
    """Đặt màu nền cho một ô bảng."""
    shading_xml = f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>'
    cell._tc.get_or_add_tcPr().append(parse_xml(shading_xml))

def set_cell_margins(cell, top=140, bottom=140, left=180, right=180):
    """Đặt padding cho ô bảng (đơn vị dxa / twentieths of a point)."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for margin_name, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{margin_name}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_borders(cell, top=None, bottom=None, left=None, right=None):
    """Đặt viền tùy chỉnh cho ô."""
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    
    borders = {'top': top, 'bottom': bottom, 'left': left, 'right': right}
    for border_name, border_style in borders.items():
        if border_style:
            # border_style: dict(val='single', sz='4', space='0', color='CBD5E1')
            node = OxmlElement(f'w:{border_name}')
            for key, val in border_style.items():
                node.set(qn(f'w:{key}'), str(val))
            tcBorders.append(node)
        else:
            node = OxmlElement(f'w:{border_name}')
            node.set(qn('w:val'), 'none')
            tcBorders.append(node)
    tcPr.append(tcBorders)

def add_header_footer(doc):
    """Thiết lập Header và Footer chuyên nghiệp cho tài liệu."""
    for s_idx, section in enumerate(doc.sections):
        # Không hiển thị header/footer ở trang bìa
        section.different_first_page_header_footer = True
        
        # Header trang sau
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("BÁO CÁO Ý TƯỞNG & THIẾT KẾ: DỰ ÁN GAME \"VƯỜN MÈO\" | ALPACA SOLUTION")
        hrun.font.name = FONT_FAMILY
        hrun.font.size = Pt(8.5)
        hrun.font.color.rgb = COLOR_MUTED_TEXT
        
        # Footer trang sau
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.LEFT
        frun1 = fp.add_run("Tài liệu nội bộ — Bảo mật · Phiên bản đặc tả GDD 0.5.0")
        frun1.font.name = FONT_FAMILY
        frun1.font.size = Pt(8.5)
        frun1.font.color.rgb = COLOR_MUTED_TEXT

def create_styled_table(doc, headers, rows_data, col_widths=None, header_bg=COLOR_PRIMARY_HEX, alt_bg=COLOR_ALT_ROW_HEX):
    """Tạo bảng với phong cách hiện đại, thanh thoát."""
    table = doc.add_table(rows=len(rows_data) + 1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    # Header Row
    header_tr = table.rows[0]
    # Repeat header on every page
    header_tr._tr.get_or_add_trPr().append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

    for idx, heading in enumerate(headers):
        cell = header_tr.cells[idx]
        set_cell_background(cell, header_bg)
        set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        run = p.add_run(heading)
        run.bold = True
        run.font.name = FONT_FAMILY
        run.font.size = Pt(9.5)
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

    # Data Rows
    border_bottom_style = {'val': 'single', 'sz': '4', 'space': '0', 'color': COLOR_BORDER_HEX}
    for row_idx, row_values in enumerate(rows_data):
        row = table.rows[row_idx + 1]
        bg_color = alt_bg if row_idx % 2 == 1 else "FFFFFF"
        for col_idx, val in enumerate(row_values):
            cell = row.cells[col_idx]
            set_cell_background(cell, bg_color)
            set_cell_margins(cell, top=110, bottom=110, left=160, right=160)
            set_cell_borders(cell, bottom=border_bottom_style)
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            run = p.add_run(str(val))
            run.font.name = FONT_FAMILY
            run.font.size = Pt(9.5)
            run.font.color.rgb = COLOR_DARK_TEXT

    # Đặt độ rộng cột nếu có
    if col_widths:
        for row in table.rows:
            for idx, width in enumerate(col_widths):
                row.cells[idx].width = Inches(width)

    # Thêm khoảng trống nhỏ sau bảng
    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_before = Pt(2)
    p_after.paragraph_format.space_after = Pt(6)
    return table

def add_callout(doc, title, paragraphs, border_hex=COLOR_CALLOUT_BORDER, bg_hex=COLOR_CALLOUT_BG):
    """Tạo hộp Callout ghi chú / điểm nhấn thiết kế nổi bật."""
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)
    set_cell_background(cell, bg_hex)
    set_cell_margins(cell, top=160, bottom=160, left=200, right=200)
    
    # Border trái dày màu accent, các border khác không có
    left_border = {'val': 'single', 'sz': '24', 'space': '0', 'color': border_hex}
    set_cell_borders(cell, left=left_border)
    
    p0 = cell.paragraphs[0]
    p0.paragraph_format.space_before = Pt(2)
    p0.paragraph_format.space_after = Pt(4)
    run_title = p0.add_run(f"★ {title}")
    run_title.bold = True
    run_title.font.name = FONT_FAMILY
    run_title.font.size = Pt(10.5)
    run_title.font.color.rgb = COLOR_SECONDARY
    
    for text in paragraphs:
        p = cell.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(3)
        run = p.add_run(text)
        run.font.name = FONT_FAMILY
        run.font.size = Pt(9.5)
        run.font.color.rgb = COLOR_DARK_TEXT
        
    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_after = Pt(6)

def add_h1(doc, text):
    """Tiêu đề Cấp 1 (Chương)"""
    h = doc.add_heading(level=1)
    h.paragraph_format.space_before = Pt(18)
    h.paragraph_format.space_after = Pt(8)
    h.paragraph_format.keep_with_next = True
    run = h.add_run(text)
    run.font.name = FONT_FAMILY
    run.font.size = Pt(17)
    run.font.bold = True
    run.font.color.rgb = COLOR_PRIMARY
    return h

def add_h2(doc, text):
    """Tiêu đề Cấp 2 (Mục)"""
    h = doc.add_heading(level=2)
    h.paragraph_format.space_before = Pt(13)
    h.paragraph_format.space_after = Pt(5)
    h.paragraph_format.keep_with_next = True
    run = h.add_run(text)
    run.font.name = FONT_FAMILY
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = COLOR_SECONDARY
    return h

def add_h3(doc, text):
    """Tiêu đề Cấp 3 (Tiểu mục)"""
    h = doc.add_heading(level=3)
    h.paragraph_format.space_before = Pt(9)
    h.paragraph_format.space_after = Pt(3)
    h.paragraph_format.keep_with_next = True
    run = h.add_run(text)
    run.font.name = FONT_FAMILY
    run.font.size = Pt(11)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    return h

def add_p(doc, text, bold_prefix="", italic=False):
    """Thêm đoạn văn chuẩn."""
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(5)
    p.paragraph_format.line_spacing = 1.2
    
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.bold = True
        r_pre.font.name = FONT_FAMILY
        r_pre.font.size = Pt(10)
        r_pre.font.color.rgb = COLOR_DARK_TEXT
        
    r_text = p.add_run(text)
    r_text.font.name = FONT_FAMILY
    r_text.font.size = Pt(10)
    r_text.font.italic = italic
    r_text.font.color.rgb = COLOR_DARK_TEXT
    return p

def add_bullet(doc, bold_prefix, text):
    """Thêm gạch đầu dòng chuẩn."""
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.bold = True
        r_pre.font.name = FONT_FAMILY
        r_pre.font.size = Pt(10)
        r_pre.font.color.rgb = COLOR_DARK_TEXT
        
    r_text = p.add_run(text)
    r_text.font.name = FONT_FAMILY
    r_text.font.size = Pt(10)
    r_text.font.color.rgb = COLOR_DARK_TEXT
    return p

def build_game_design_document(output_path):
    print(f"Bắt đầu khởi tạo tài liệu Word GDD tại: {output_path}")
    doc = docx.Document()
    
    # Thiết lập lề trang chuẩn A4 (2.5 cm = ~0.984 inch)
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.0)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.27)
        section.page_height = Inches(11.69)
        
    add_header_footer(doc)
    
    # ==========================================
    # TRANG BÌA (COVER PAGE)
    # ==========================================
    p_company = doc.add_paragraph()
    p_company.paragraph_format.space_before = Pt(30)
    p_company.paragraph_format.space_after = Pt(5)
    r_comp = p_company.add_run("CÔNG TY TNHH GIẢI PHÁP CÔNG NGHỆ ALPACA (ALPACA SOLUTION)")
    r_comp.bold = True
    r_comp.font.name = FONT_FAMILY
    r_comp.font.size = Pt(10)
    r_comp.font.color.rgb = COLOR_MUTED_TEXT

    p_proj = doc.add_paragraph()
    p_proj.paragraph_format.space_before = Pt(0)
    p_proj.paragraph_format.space_after = Pt(40)
    r_proj = p_proj.add_run("DỰ ÁN GAME ASOL-03 · TÀI LIỆU CHIẾN LƯỢC SẢN PHẨM & THIẾT KẾ CHI TIẾT")
    r_proj.bold = True
    r_proj.font.name = FONT_FAMILY
    r_proj.font.size = Pt(10)
    r_proj.font.color.rgb = COLOR_SECONDARY

    # Tiêu đề chính
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(20)
    p_title.paragraph_format.space_after = Pt(10)
    r_title = p_title.add_run("BÁO CÁO Ý TƯỞNG & THIẾT KẾ GAME\n(GAME DESIGN DOCUMENT)")
    r_title.bold = True
    r_title.font.name = FONT_FAMILY
    r_title.font.size = Pt(24)
    r_title.font.color.rgb = COLOR_PRIMARY

    # Tên dự án
    p_gamename = doc.add_paragraph()
    p_gamename.paragraph_format.space_before = Pt(5)
    p_gamename.paragraph_format.space_after = Pt(25)
    r_game = p_gamename.add_run("DỰ ÁN: VƯỜN MÈO (CAT GARDEN)\n")
    r_game.bold = True
    r_game.font.name = FONT_FAMILY
    r_game.font.size = Pt(18)
    r_game.font.color.rgb = COLOR_ACCENT
    
    r_gamesub = p_gamename.add_run("Tựa game giải đố suy luận logic thư giãn (Cozy Logic Puzzle) trên thiết bị di động")
    r_gamesub.font.name = FONT_FAMILY
    r_gamesub.font.size = Pt(12)
    r_gamesub.font.italic = True
    r_gamesub.font.color.rgb = COLOR_MUTED_TEXT

    # Bảng metadata bìa
    doc.add_paragraph().paragraph_format.space_after = Pt(40)
    meta_headers = ["Thông tin phân loại", "Chi tiết đặc tả dự án"]
    meta_rows = [
        ["Tên dự án (Working Title)", "Vườn Mèo (Cat Garden) — Mã dự án: ASOL-Game-02"],
        ["Thể loại (Genre)", "Logic Puzzle / Single-player Grid Deduction (Star Battle style)"],
        ["Nền tảng mục tiêu (Platform)", "iOS & Android (Màn hình dọc - Portrait, Hoạt động Offline 100%)"],
        ["Engine phát triển", "Godot Engine 4.x (GDScript, Pipeline đồ họa 2D từ 3D Blender)"],
        ["Phiên bản tài liệu (Version)", "0.5.0 (Candidate Specification hướng tới GDD v1.0)"],
        ["Ngày lập báo cáo", "21/09/2026"],
        ["Tác giả / Bộ phận", "Alpaca Solution Game Design & Architecture Team"],
        ["Trạng thái hiện tại", "Đã chốt toàn diện GDD & Architecture, hoàn thiện Validator v4 & Bộ Test"]
    ]
    create_styled_table(doc, meta_headers, meta_rows, col_widths=[2.5, 4.0])

    doc.add_page_break()

    # ==========================================
    # TÓM TẮT ĐIỀU HÀNH (EXECUTIVE SUMMARY)
    # ==========================================
    add_h1(doc, "TÓM TẮT ĐIỀU HÀNH (EXECUTIVE SUMMARY)")
    
    add_p(doc, 
          "\"Vườn Mèo\" (tên tạm thời) là dự án game giải đố suy luận một người chơi trên thiết bị di động (màn hình dọc), "
          "được thiết kế theo định hướng trải nghiệm ấm cúng, thư giãn (Cozy Game) nhưng kích thích trí tuệ sâu sắc. "
          "Trò chơi phát triển dựa trên nền tảng luật kinh điển của dòng giải đố Star Battle (được đánh giá cao về tính logic thuần túy), "
          "kết hợp với hình tượng loài mèo gần gũi, đáng yêu được dựng hình 3D nguyên bản và xuất thành sprite 2D mượt mà.")

    add_callout(doc, "BẢN SẮC & CAM KẾT NGUYÊN BẢN CỦA DỰ ÁN", [
        "100% Asset nguyên bản: Toàn bộ model 3D, animation, sprite 2D, hiệu ứng âm thanh và câu chữ đều được xây dựng gốc từ đội ngũ, cam kết không sao chép bất kỳ tài sản sở hữu trí tuệ nào từ các game tham chiếu trên thị trường (như Meowdoku).",
        "Logic toán học chuẩn xác: 100% màn chơi (level) được đảm bảo có đúng một nghiệm duy nhất (unique solution) và giải được hoàn toàn bằng chuỗi suy luận logic thuần túy, tuyệt đối không đòi hỏi người chơi phải đoán mò (no guesswork).",
        "Thiết kế công thái học không ma sát: Không dùng cơ chế đổi công cụ phức tạp; người chơi thực hiện mọi thao tác đặt X, xóa X, kéo dải ô và xác nhận mèo thông qua hệ thống chạm/kéo/chạm đôi cực kỳ trực quan."
    ])

    add_h2(doc, "Bốn Trụ Cột Trải Nghiệm (Core Product Pillars)")
    add_bullet(doc, "1. Trí tuệ thuần khiết (Pure Mindful Deduction): ", 
               "Luật chơi tối giản, dễ hiểu chỉ sau 1 phút hướng dẫn nhưng chiều sâu suy luận tăng dần theo cấp số. Mọi bước đi đều có thể chứng minh logic thông qua các quy tắc loại trừ (S1), ứng viên đơn (S2) và khóa giao thoa (S3).")
    add_bullet(doc, "2. Trải nghiệm không áp lực (Cozy & Stress-Free): ", 
               "Không tính giờ đếm ngược, không hiện điểm số dồn dập trong lúc chơi; điểm số chỉ là scorecard thành tích nhẹ nhàng hiển thị sau khi hoàn thành. Game vận hành hoàn toàn offline, mang lại cảm giác bình yên.")
    add_bullet(doc, "3. Thao tác cảm ứng mượt mà (Zero-Friction Gesture): ", 
               "Chạm 1 lần để đánh/xóa X tức thì; giữ và rê để tô hàng loạt ô; chạm đôi 280ms để xác nhận mèo. Hệ thống Undo 1 bước thông minh và Restart có xác nhận giúp kiểm soát ván chơi hoàn hảo.")
    add_bullet(doc, "4. Tự động hóa kiểm thử nội dung (Automated Content Pipeline): ", 
               "Bộ công cụ Python Validator kiểm tra toàn diện schema v4, nghiệm duy nhất, trace suy luận và lọc trùng lặp hình học qua 8 phép biến đổi đối xứng, bảo chứng chất lượng trước mọi bản cập nhật.")

    # Bảng factsheet
    add_h2(doc, "Bảng Thông Số Tổng Quan (Game Factsheet)")
    fact_headers = ["Thông số", "Đặc tả chi tiết trong phiên bản MVP"]
    fact_rows = [
        ["Thể loại", "Logic Puzzle / Single-player Grid Deduction"],
        ["Định dạng màn hình", "Màn hình dọc (Vertical / Portrait Mode) cho điện thoại di động"],
        ["Quy mô nội dung MVP", "24 Level gốc được biên tập thủ công, kích thước bàn N=4×4 đến N=6×6"],
        ["Mở rộng kiến trúc", "Schema và Core hỗ trợ sẵn sàng mở rộng đến N=12×12 (12 vùng/mèo/màu)"],
        ["Mức độ suy luận", "Level 1–18: Suy luận S1/S2; Level 19–24: Bắt buộc chứa bước suy luận nâng cao S3"],
        ["Cơ chế mạng & Monetization", "Hoàn toàn Offline, không quảng cáo ép buộc, không IAP trong bản đầu"],
        ["Ngôn ngữ khởi đầu", "Tiếng Việt (thiết kế sẵn hệ thống localization để hỗ trợ đa ngôn ngữ)"],
        ["Thời lượng 1 ván", "1 – 3 phút (màn nhỏ 4×4) đến 3 – 6 phút (màn nâng cao 5×5, 6×6)"],
        ["Đối tượng người chơi", "Casual/Mid-core Puzzle gamer, yêu thích mèo, chuộng game thư giãn rèn luyện trí não"]
    ]
    create_styled_table(doc, fact_headers, fact_rows, col_widths=[2.2, 4.3])

    # ==========================================
    # CHƯƠNG 1: Ý TƯỞNG SẢN PHẨM & TẦM NHÌN
    # ==========================================
    add_h1(doc, "CHƯƠNG 1: Ý TƯỞNG SẢN PHẨM & TẦM NHÌN (PRODUCT VISION)")
    
    add_h2(doc, "1.1. Bối cảnh & Cốt truyện Thư Giãn (The Cozy Garden)")
    add_p(doc, 
          "Trò chơi mở ra một khu vườn thanh bình được chia thành nhiều ô đất với các thảm hoa và cảnh quan rực rỡ sắc màu. "
          "Tại đây, những chú mèo tinh nghịch đang chơi trò trốn tìm. Mỗi khu vực, mỗi hàng và mỗi cột trong khu vườn đều chỉ có "
          "duy nhất một vị trí ấm áp và lý tưởng nhất cho một chú mèo nằm nghỉ ngơi. Hơn thế nữa, các chú mèo vốn có tập tính độc lập, "
          "chúng không thích nằm quá gần nhau (kể cả chạm góc chéo).")
    add_p(doc, 
          "Người chơi trong vai trò người chăm sóc khu vườn sẽ vận dụng tư duy logic tinh tế để suy luận và đánh dấu các vị trí không có mèo "
          "(bằng dấu cỏ cây/dấu X), từ đó tìm ra chính xác vị trí của tất cả các chú mèo đang ẩn nấp. Mỗi khi một chú mèo được phát hiện, "
          "nó sẽ nhảy lên vui sướng và cảm ơn người chơi bằng những tiếng meow ngọt ngào.")

    add_h2(doc, "1.2. Phân Tích Thị Trường & Lợi Thế Cạnh Tranh (USP)")
    add_p(doc, 
          "Thị trường game giải đố trên di động hiện nay có hàng triệu lượt tải nhưng đang phân hóa mạnh mẽ giữa hai thái cực:")
    add_bullet(doc, "Nhóm Sudoku / Nonogram cổ điển: ", 
               "Tính trí tuệ rất cao nhưng đồ họa khô khan, mang nặng cảm giác tính toán số học, bảng tính phức tạp, tạo áp lực tâm lý cho người chơi phổ thông.")
    add_bullet(doc, "Nhóm Match-3 / Merge game: ", 
               "Đồ họa bắt mắt nhưng lạm dụng yếu tố may rủi (RNG), cơ chế ép trả phí (Pay-to-win) và quảng cáo ngắt quãng trải nghiệm.")
    add_bullet(doc, "Cơ hội từ dòng Star Battle cách tân (như Meowdoku): ", 
               "Chứng minh tiềm năng khổng lồ khi kết hợp luật giải đố logic thuần khiết với chủ đề động vật dễ thương. Tuy nhiên, nhiều sản phẩm vẫn gặp điểm nghẽn về UI/UX (thao tác chọn tool rườm rà, level sinh ngẫu nhiên dễ dính bẫy suy đoán, thiếu kiểm định logic chặt chẽ).")

    add_p(doc, "Dự án \"Vườn Mèo\" của Alpaca Solution định vị là giải pháp vượt trội với 3 Lợi thế cạnh tranh cốt lõi (USP):")
    add_bullet(doc, "1. Trải nghiệm điều khiển đột phá: ", 
               "Loại bỏ thanh công cụ chuyển đổi giữa bút chì/đặt mèo. Cơ chế nhận diện cử chỉ thông minh (Chạm đơn preview X, Kéo liên hoàn, Chạm đôi đặt mèo) giúp thao tác nhanh gấp 2 lần và giảm thiểu lỗi bấm nhầm.")
    add_bullet(doc, "2. Chất lượng thiết kế màn chơi đỉnh cao: ", 
               "Mọi màn chơi trong chiến dịch đều được kiểm định tự động bằng hệ thống Trace Checker chuyên biệt. Không có màn chơi nào bắt người chơi phải đoán mò (guessing). Mọi câu đố đều có lời giải thích logic minh bạch.")
    add_bullet(doc, "3. Thẩm mỹ tinh tế & Độc lập nhận diện: ", 
               "Hình tượng mèo cưng được dựng 3D gốc với cá tính sinh động, chuyển động mượt mà. Hệ thống màu sắc vùng kết hợp hoa văn hình học giúp người chơi mù màu hoàn toàn có thể trải nghiệm trọn vẹn.")

    add_h2(doc, "1.3. Khán Giả Mục Tiêu (Target Audience)")
    add_bullet(doc, "Khán giả Casual/Cozy Gamers (18–45 tuổi): ", 
               "Yêu thích động vật (đặc biệt là mèo), tìm kiếm trải nghiệm nhẹ nhàng giải tỏa căng thẳng sau giờ làm việc, chuộng phong cách mỹ thuật ấm áp, không áp lực cạnh tranh.")
    add_bullet(doc, "Cộng đồng Đam mê Puzzle / Logic (Brain Training): ", 
               "Thích thử thách trí tuệ chuẩn xác, yêu cầu tính công bằng tuyệt đối trong luật chơi, thỏa mãn cảm giác \"Aha!\" khi tự mình khám phá ra chuỗi suy luận hóc búa.")

    add_h2(doc, "1.4. Vòng Lặp Trải Nghiệm (Core Gameplay Loop)")
    add_p(doc, 
          "Vòng lặp cốt lõi được xây dựng theo chu trình khép kín, tinh gọn và tạo động lực tự nhiên:")
    add_p(doc, 
          "Mở Game ➔ Vào Level hiện tại ➔ Phân tích bàn cờ ➔ Đánh/Xóa X loại trừ bằng chạm/kéo ➔ "
          "Xác nhận mèo bằng chạm đôi ➔ Phản hồi tích cực (\"Nice!\" / \"Great!\") ➔ "
          "Tìm đủ N chú mèo ➔ Màn Thắng hoan hỉ & Xem Scorecard ➔ Chuyển sang Level kế tiếp.", italic=True)

    # ==========================================
    # CHƯƠNG 2: THIẾT KẾ LUẬT CHƠI & CƠ CHẾ
    # ==========================================
    add_h1(doc, "CHƯƠNG 2: THIẾT KẾ LUẬT CHƠI & CƠ CHẾ CỐT LÕI (GAMEPLAY MECHANICS)")
    
    add_p(doc, 
          "Hệ thống luật chơi được chuẩn hóa tại tài liệu kỹ thuật GDD-02, định nghĩa chính xác không gian trạng thái toán học "
          "và tương tác người dùng trên bàn cờ kích thước N×N.")

    add_h2(doc, "2.1. Cấu Trúc Bàn Cờ & 4 Quy Tắc Cốt Lõi (Core Rules GR-01 .. GR-04)")
    add_p(doc, 
          "Bàn cờ là một lưới vuông kích thước N×N ô. Bàn cờ được phân chia thành đúng N vùng màu liên thông 4 hướng (orthogonal connectivity). "
          "Nhiệm vụ của người chơi là xác định chính xác N vị trí đặt mèo thỏa mãn đồng thời 4 quy tắc bắt buộc:")

    rules_table_headers = ["Mã luật", "Nội dung quy tắc chuẩn", "Ý nghĩa trong gameplay"]
    rules_table_rows = [
        ["GR-01", "Mỗi hàng có đúng 1 chú mèo", "Không có hàng nào bị bỏ trống và không có hàng nào chứa từ 2 mèo trở lên."],
        ["GR-02", "Mỗi cột có đúng 1 chú mèo", "Tương tự hàng, mỗi cột dọc chỉ chứa đúng 1 vị trí mèo duy nhất."],
        ["GR-03", "Mỗi vùng màu có đúng 1 chú mèo", "Mỗi khối vùng liên thông (nhãn A..N) có đúng 1 chú mèo trú ngụ."],
        ["GR-04", "Mèo không chạm nhau kể cả góc chéo", "Mỗi chú mèo chiếm giữ một vùng cấm xung quanh gồm 8 ô lân cận (ngang, dọc, chéo). Hai mèo không bao giờ nằm cạnh nhau."],
        ["GR-05", "Đúng một nghiệm duy nhất", "Toàn bộ bài toán (kể cả mèo cho sẵn nếu có) chỉ có đúng 1 cấu hình nghiệm duy nhất được solver chứng minh."]
    ]
    create_styled_table(doc, rules_table_headers, rules_table_rows, col_widths=[1.0, 2.7, 2.8])

    add_h2(doc, "2.2. Bốn Trạng Thái Ô Trên Bàn Cờ (Cell States)")
    add_p(doc, "Mỗi ô trên bàn cờ chỉ có thể thuộc 1 trong 4 trạng thái duy nhất sau:")
    add_bullet(doc, "1. Ô trống (`empty`): ", "Ô chưa có thao tác, có thể đánh X hoặc thử đặt mèo.")
    add_bullet(doc, "2. Ô đánh dấu X (`x`): ", "Ghi chú do người chơi tự đặt để đánh dấu rằng ô này không thể có mèo. Dấu X có màu trung tính, có thể xóa bất kỳ lúc nào.")
    add_bullet(doc, "3. Ô sai bị khóa (`x_error`): ", "Xuất hiện khi người chơi thử đặt mèo tại ô không thuộc nghiệm. Ô biến thành dấu X đỏ đậm kèm biểu tượng cảnh báo và ổ khóa. Ô này bị khóa vĩnh viễn trong suốt lượt chơi (không thể xóa hay Undo).")
    add_bullet(doc, "4. Ô mèo đúng (`cat`): ", "Ô đã được xác nhận đặt mèo thành công (hoặc là mèo cho sẵn - Given từ đầu màn). Ô mèo hiển thị hình ảnh chú mèo cưng nhảy múa và cố định vĩnh viễn.")

    add_h2(doc, "2.3. Hệ Thống Điều Khiển Trực Quan (Zero-Tool Gesture System)")
    add_p(doc, 
          "Điểm đột phá của game là loại bỏ hoàn toàn thanh công cụ (không bắt người chơi bấm nút chuyển giữa 'cây bút X' và 'con mèo'). "
          "Người chơi thao tác mượt mà bằng cử chỉ tự nhiên:")

    gesture_headers = ["Thao tác cử chỉ", "Trạng thái ô ban đầu", "Hành động & Phản hồi của hệ thống"]
    gesture_rows = [
        ["Chạm đơn (Single Tap)", "Ô trống (empty)", "Hiển thị ngay dấu X xem trước (preview). Mở cửa sổ chờ 280ms. Nếu hết 280ms không có chạm tiếp theo, chính thức xác nhận dấu X."],
        ["Chạm đơn (Single Tap)", "Ô dấu X (x)", "Xóa ngay dấu X xem trước về ô trống. Hết 280ms chính thức xác nhận xóa."],
        ["Chạm và Rê (Drag Stroke)", "Kéo từ ô trống", "Ngưỡng kéo > 12 điểm logic: Kích hoạt chế độ 'Tô X liên hoàn'. Mọi ô trống ngón tay lướt qua đều được đánh dấu X tức thì."],
        ["Chạm và Rê (Drag Stroke)", "Kéo từ ô có X", "Kích hoạt chế độ 'Xóa X liên hoàn'. Mọi ô có dấu X ngón tay lướt qua đều được xóa sạch tức thì."],
        ["Chạm đôi nhanh (Double Tap)", "Cùng một ô (empty hoặc x)", "Chạm 2 lần liên tiếp lên cùng 1 ô trong vòng 280ms: Hủy ngay preview X, gọi lệnh Thử Đặt Mèo (TryCat)."],
        ["Hoàn tác 1 bước (Undo)", "Nút Undo trên màn hình", "Chỉ hoàn nguyên hành động đánh/xóa X gần nhất (một ô hoặc một nét kéo). Thao tác đặt mèo TryCat không thể Undo."],
        ["Khởi động lại (Restart)", "Nút Restart góc trên", "Hiện hộp thoại xác nhận an toàn: 'Bắt đầu lại màn chơi?'. Nếu đồng ý, tạo lượt mới trên cùng màn chơi đó."]
    ]
    create_styled_table(doc, gesture_headers, gesture_rows, col_widths=[1.8, 1.8, 2.9])

    add_h2(doc, "2.4. Hệ Thống Tim, Phạt Sai & Màn Thua")
    add_bullet(doc, "3 Trái Tim Mỗi Lượt Chơi: ", "Mỗi khi vào màn chơi, người chơi có 3 trái tim hiển thị trên thanh header.")
    add_bullet(doc, "Cơ chế phạt sai: ", "Khi người chơi chạm đôi thử đặt mèo tại ô sai (không khớp với nghiệm), ô đó lập tức biến thành X đỏ khóa (`x_error`), điện thoại rung nhẹ và người chơi bị trừ đúng 1 trái tim.")
    add_bullet(doc, "Màn Kết Quả Thua (Defeat Result): ", "Khi hết cả 3 trái tim, trò chơi dừng lại và hiển thị màn kết quả thua. Người chơi có thể chọn 'Thử lại' (Retry) hoàn toàn miễn phí để làm lại màn chơi đó từ đầu với 3 tim đầy đủ.")

    add_h2(doc, "2.5. Hệ Thống Tính Điểm (Scorecard)")
    add_p(doc, 
          "Nhằm duy trì tinh thần thư giãn, điểm số hoàn toàn KHÔNG hiển thị trong quá trình giải đố để tránh gây áp lực thời gian hay điểm số lên người chơi. "
          "Điểm số chỉ được tính toán nội bộ và hiển thị trên Scorecard ở màn hình Kết quả cuối ván.")
    add_p(doc, 
          "Công thức tính điểm chuẩn: Score = max(0, 100 × Số mèo đúng tự tìm − 25 × Số lần sai)", bold_prefix="Công thức toán học: ")
    add_bullet(doc, "Cộng điểm: ", "+100 điểm cho mỗi chú mèo đúng do người chơi tự tìm thấy. Mèo cho sẵn từ đầu (givens) không tính điểm.")
    add_bullet(doc, "Trừ điểm: ", "-25 điểm cho mỗi lần thử sai (mất tim). Điểm số có sàn tối thiểu là 0 (không âm).")
    add_bullet(doc, "Yếu tố trung tính: ", "Thời gian giải ván cờ, việc sử dụng gợi ý (Hint) hay số lượng dấu X đánh ra KHÔNG cộng/trừ điểm.")

    add_h2(doc, "2.6. Hệ Thống Gợi Ý Thông Minh (Intelligent Hint Engine)")
    add_p(doc, 
          "Mỗi lượt chơi cung cấp đúng 1 lượt Gợi ý (Hint) miễn phí. Khác với các game giải đố thông thường (chỉ đơn giản là tự điền đáp án cho người chơi), "
          "Hint Engine của Vườn Mèo hoạt động như một người thầy dạy tư duy logic:")
    add_bullet(doc, "Dựa trên suy luận hình thức: ", "Hệ thống quét trạng thái bàn cờ hiện tại và tìm ra bước suy luận S2 (ứng viên đơn) hoặc S3 (khóa giao thoa) khả thi gần nhất.")
    add_bullet(doc, "Tô sáng chứng cứ (Visual Evidence): ", "Hệ thống làm nổi bật vùng/hàng/cột liên quan, chỉ ra các ô đã bị loại trừ bởi những chú mèo nào, và giải thích vì sao ô đích bắt buộc phải có mèo.")
    add_bullet(doc, "Không làm mất quyền tương tác: ", "Hint chỉ hướng dẫn và tô sáng chứng cứ; chính người chơi phải là người thực hiện chạm đôi để xác nhận chú mèo đó.")

    # ==========================================
    # CHƯƠNG 3: HỆ THỐNG SUY LUẬN & LEVEL
    # ==========================================
    add_h1(doc, "CHƯƠNG 3: HỆ THỐNG SUY LUẬN & THIẾT KẾ LEVEL (LOGIC & CONTENT)")

    add_h2(doc, "3.1. Phân Cấp Quy Tắc Suy Luận Hình Thức (Deduction Rules)")
    add_p(doc, 
          "Để đảm bảo chất lượng giải đố đỉnh cao, toàn bộ các màn chơi được xây dựng dựa trên 3 cấp độ suy luận hình thức chặt chẽ:")

    logic_headers = ["Cấp độ", "Tên quy tắc suy luận", "Nguyên lý toán học & Ứng dụng trong game"]
    logic_rows = [
        ["S1", "Loại trừ cơ bản (Basic Elimination)", 
         "Khi một chú mèo đã được xác định tại (r, c), toàn bộ các ô khác trên cùng hàng r, cùng cột c, cùng vùng màu và 8 ô lân cận xung quanh đều bị loại trừ (chắc chắn không có mèo). Đây là bằng chứng trực tiếp được suy ra từ 4 luật cơ bản."],
        ["S2", "Ứng viên duy nhất (Single Candidate)", 
         "Trong một đơn vị (hàng, cột hoặc vùng màu), sau khi đã loại trừ các ô bất khả thi theo S1, nếu chỉ còn lại đúng 1 ô trống duy nhất thì ô đó bắt buộc phải chứa mèo. Người chơi tự tin xác nhận mèo tại đây."],
        ["S3", "Khóa giao thoa (Locked Intersection)", 
         "Kỹ thuật suy luận nâng cao: Nếu tất cả các ô ứng viên còn lại của một Vùng màu nằm trọn vẹn trên cùng một Hàng (hoặc Cột), thì chú mèo của vùng đó chắc chắn nằm trên hàng đó. Do đó, toàn bộ các ô ứng viên khác trên hàng đó (ngoài vùng này) đều bị loại trừ hoàn toàn!"]
    ]
    create_styled_table(doc, logic_headers, logic_rows, col_widths=[0.8, 2.4, 3.3])

    add_h2(doc, "3.2. Cấu Trúc Chiến Dịch 24 Level Ban Đầu (Release Campaign 1–24)")
    add_p(doc, 
          "Chiến dịch ra mắt gồm 24 màn chơi được thiết kế thủ công tinh tế với đường cong độ khó (difficulty curve) khoa học:")

    campaign_headers = ["Thứ tự Level", "Kích thước", "Mục tiêu bài học", "Cấp suy luận", "Thời lượng trung bình"]
    campaign_rows = [
        ["Level 1", "4×4", "Màn hướng dẫn duy nhất (Tutorial T1–T6): Chạm X, xóa X, kéo X, chạm đôi mèo, 4 luật cơ bản, giải thích dấu X đỏ an toàn.", "S1 / S2", "1 – 3 phút"],
        ["Level 2 – 4", "4×4", "Áp dụng đầy đủ luật phạt tim; củng cố kỹ năng quét hàng, cột, vùng và quy tắc không chạm góc.", "S1 / S2", "1 – 3 phút / level"],
        ["Level 5 – 12", "4×4 – 5×5", "Phát triển tư duy dùng mèo vừa tìm thấy để loại trừ dây chuyền. Level 10 là mốc đặc biệt với bố cục đối xứng.", "S1 / S2", "2 – 4 phút / level"],
        ["Level 13 – 18", "5×5 – 6×6", "Chuỗi suy luận S2 dài hơn, giảm dần số lượng mèo cho sẵn (Givens). Đòi hỏi khả năng bao quát toàn bàn cờ.", "S1 / S2", "3 – 5 phút / level"],
        ["Level 19 – 24", "5×5 – 6×6", "Thử thách trí tuệ thực thụ: Mỗi level BẮT BUỘC phải yêu cầu ít nhất một bước suy luận nâng cao S3. Level 20 là mốc đỉnh cao.", "S2 + Bắt buộc S3", "3 – 6 phút / level"]
    ]
    create_styled_table(doc, campaign_headers, campaign_rows, col_widths=[1.1, 0.9, 2.2, 1.1, 1.2])

    add_h2(doc, "3.3. Quy Trình Kiểm Định & Đóng Gói Tự Động (Automated Content Pipeline)")
    add_p(doc, 
          "Mọi level trong dự án đều phải vượt qua công cụ tự động `validate_levels.py` với các chốt chặn chất lượng khắt khe trước khi được đóng gói:")
    add_bullet(doc, "1. Kiểm tra Schema JSON v4: ", "Đảm bảo đúng chuẩn định dạng, tọa độ hợp lệ, kích thước N từ 4 đến 12, nhãn vùng A..L liên tục.")
    add_bullet(doc, "2. Kiểm tra tính liên thông vùng: ", "Mọi vùng màu đều phải liên thông 4 hướng (orthogonal flood-fill), không có vùng bị đứt đoạn hoặc cô lập.")
    add_bullet(doc, "3. Giải nghiệm độc lập (Uniqueness Solver): ", "Bộ giải thuật độc lập quét toàn bộ không gian nghiệm; nếu tìm thấy nghiệm thứ 2 thì level lập tức bị từ chối.")
    add_bullet(doc, "4. Kiểm tra vết suy luận (Logic Trace): ", "Mỗi bước đi trong level phải được chứng minh tuần tự bằng toán học. Level 1–18 không chứa S3, Level 19–24 bắt buộc phải cần S3 (nếu giải được chỉ bằng S2 sẽ bị đánh rớt).")
    add_bullet(doc, "5. Lọc trùng lặp hình học 8 chiều (Duplicate Filter): ", "Hệ thống chuẩn hóa hình dạng vùng qua 8 phép biến đổi đối xứng (xoay 90°, 180°, 270°, lật ngang, lật dọc và hoán vị nhãn). Trong cửa sổ trượt 8 level liên tiếp không được phép có hai level tương đương hình học.")

    # ==========================================
    # CHƯƠNG 4: LUỒNG MÀN HÌNH & TRẢI NGHIỆM UX
    # ==========================================
    add_h1(doc, "CHƯƠNG 4: LUỒNG MÀN HÌNH & TRẢI NGHIỆM NGƯỜI DÙNG (SCREEN FLOW & UX)")

    add_h2(doc, "4.1. Sơ Đồ Điều Hướng Tuyến Tính (Linear Screen Flow)")
    add_p(doc, 
          "Để người chơi hoàn toàn đắm chìm vào trải nghiệm giải đố mà không bị phân tâm bởi các giao diện phụ, "
          "phiên bản MVP áp dụng luồng điều hướng tuyến tính, tinh giản tuyệt đối (loại bỏ màn hình bản đồ/chọn màn):")
    add_bullet(doc, "Màn hình Khởi động (Home): ", "Hiển thị nút 'Tiếp tục chơi' (dẫn ngay vào level hiện tại), số thứ tự level hiện tại, nút 'Trợ giúp/Luật' và 'Cài đặt'.")
    add_bullet(doc, "Màn hình Chơi đố (Puzzle Game Screen): ", "Không gian chơi chính với bàn cờ tối ưu diện tích, thanh luật 4 icon cố định và hàng tiến độ vùng trực quan.")
    add_bullet(doc, "Hai Màn hình Kết quả Riêng biệt: ", "Tách bạch rõ ràng giữa màn Thắng (Victory) tươi vui, thưởng sticker chúc mừng và màn Thua (Defeat) đồng cảm, hỗ trợ Thử lại ngay lập tức.")

    add_h2(doc, "4.2. Bố Cục Màn Hình Dọc Chuẩn Công Thái Học (Portrait Ergonomics)")
    add_p(doc, 
          "Màn hình chơi game (Puzzle Screen) được bố trí từ trên xuống dưới theo nguyên lý công thái học một tay:")
    add_bullet(doc, "1. Thanh Tiêu đề (Header - Safe Area): ", "Nút Home (quay về trang chủ và tự lưu ván), Tên level ('Level 05'), Chỉ báo 3 Tim, Nút Khởi động lại (Restart có xác nhận) và Cài đặt.")
    add_bullet(doc, "2. Vùng Luật 4 Icon Cố Định: ", "Nằm ngay dưới Header, luôn luôn hiển thị 4 biểu tượng ngắn gọn (1 mèo/hàng, 1 mèo/cột, 1 mèo/vùng, không chạm nhau). Giúp người chơi mới luôn ghi nhớ luật mà không cần mở menu.")
    add_bullet(doc, "3. Bàn cờ trung tâm (Game Board): ", "Khu vực ưu tiên diện tích lớn nhất. Trên bàn N=6, mỗi ô có kích thước vùng chạm tối thiểu 44×44 pt để tránh bấm nhầm.")
    add_bullet(doc, "4. Hàng Tiến Độ Vùng N vị trí: ", "Hiển thị N biểu tượng tương ứng với N vùng màu A..(N). Khi vùng nào tìm được mèo, biểu tượng vùng đó sẽ sáng lên và đổi màu rực rỡ.")
    add_bullet(doc, "5. Thanh Công cụ Dưới đáy (Toolbar): ", "Gồm các nút bấm thao tác phụ: Nút Hoàn tác (Undo 1 bước dấu X), Nút Gợi ý (Hint - hiển thị số lượng 1/1) và Nút Trợ giúp luật chi tiết.")

    add_h2(doc, "4.3. Tiêu Chuẩn Trợ Năng & Hòa Nhập (Accessibility Standards)")
    add_bullet(doc, "Hỗ trợ người khiếm thị màu (Colorblind Accessibility): ", 
               "Màu sắc không bao giờ là kênh truyền tải thông tin duy nhất. Mỗi vùng màu luôn đi kèm đồng thời: Tên nhãn chữ cái (A, B, C...) và Hoa văn hình học độc nhất (chấm bi, sọc ngang, caro, sóng nước, vòng tròn...).")
    add_bullet(doc, "Chế độ Giảm chuyển động (Reduced Motion): ", 
               "Người chơi nhạy cảm với hiệu ứng có thể bật chế độ này trong Settings; các hoạt ảnh nhảy nhót, rung lắc sẽ được thay thế bằng hiệu ứng mờ dần (fade) nhẹ nhàng.")
    add_bullet(doc, "Tương thích âm thanh & xúc giác độc lập: ", 
               "Âm thanh (SFX) và Rung (Haptics) có hai công tắc bật/tắt hoàn toàn độc lập. Người chơi tắt toàn bộ âm thanh vẫn nắm bắt 100% diễn biến game thông qua thị giác.")

    # ==========================================
    # CHƯƠNG 5: ĐỊNH HƯỚNG MỸ THUẬT & ÂM THANH
    # ==========================================
    add_h1(doc, "CHƯƠNG 5: ĐỊNH HƯỚNG MỸ THUẬT & ÂM THANH (ART & AUDIO)")

    add_h2(doc, "5.1. Phong Cách Thẩm Mỹ (Art Aesthetic: Cozy Garden)")
    add_p(doc, 
          "Định hướng mỹ thuật hướng đến cảm xúc ấm cúng, thư thái với bảng màu pastel tự nhiên của cỏ cây, hoa lá và ánh nắng. "
          "Giao diện được thiết kế phẳng, hiện đại với các góc bo tròn mềm mại, tạo cảm giác thân thiện và cao cấp.")

    add_h2(doc, "5.2. Pipeline Đồ Họa 3D sang 2D Sprite Sheet")
    add_p(doc, 
          "Để kết hợp hoàn hảo giữa vẻ đẹp sinh động của mô hình 3D và sự tối ưu tuyệt đối về hiệu năng trên thiết bị di động tầm thấp, "
          "dự án lựa chọn quy trình sản xuất đồ họa kết hợp:")
    add_bullet(doc, "1. Dựng hình & Diễn hoạt 3D trong Blender: ", 
               "Tạo dựng model nhân vật mèo gốc (nguyên bản 100%), gắn xương (rig) và làm chuyển động cho 4 trạng thái cốt lõi: Đứng thở (idle), Nhảy lên khi tìm đúng (jump), Nhảy múa ăn mừng chiến thắng (celebrate) và Tiếc nuối khi người chơi chọn sai (sad).")
    add_bullet(doc, "2. Xuất bản thành Sprite Sheet 2D: ", 
               "Render sẵn các chuỗi hoạt ảnh thành sprite sheet 2D với cùng góc máy, ánh sáng chuẩn và nền trong suốt. Godot Engine sẽ phát các chuỗi sprite này bằng node AnimatedSprite2D.")
    add_bullet(doc, "3. Tối ưu hóa bộ nhớ: ", 
               "Mỗi giống mèo chỉ dùng đúng MỘT bộ sprite sheet duy nhất. Màu sắc vùng không nhuộm lên lông mèo mà được thể hiện ở nền và viền ô bàn cờ. Giải pháp này giúp tiết kiệm 85% dung lượng VRAM so với việc nhân bản sprite theo từng màu.")

    add_h2(doc, "5.3. Bảng Màu Khởi Đầu 6 Vùng & Hoa Văn Hỗ Trợ")
    add_p(doc, "Bảng màu khởi đầu cho các bàn cờ N=4 đến N=6 trong phiên bản phát hành đầu tiên:")

    color_headers = ["Nhãn vùng", "Tên màu sắc", "Mã Hex đề xuất", "Hoa văn hỗ trợ (Colorblind Pattern)"]
    color_rows = [
        ["Vùng A", "San hô ấm áp (Coral)", "#D76F5D", "Chấm bi tròn (Dots)"],
        ["Vùng B", "Xanh ngọc thanh mát (Teal)", "#328F83", "Sọc kẻ ngang (Horizontal Stripes)"],
        ["Vùng C", "Vàng mật ngọt ngào (Honey)", "#A97617", "Gạch chéo caro (Crosshatch)"],
        ["Vùng D", "Tím oải hương (Lavender)", "#8B6EB3", "Ô vuông nhỏ (Squares)"],
        ["Vùng E", "Xanh trời bình yên (Sky)", "#397FAC", "Đường sóng nước (Waves)"],
        ["Vùng F", "Hồng mận dịu dàng (Plum)", "#AD6287", "Vòng tròn đồng tâm (Circles)"]
    ]
    create_styled_table(doc, color_headers, color_rows, col_widths=[1.0, 2.0, 1.5, 2.0])

    add_h2(doc, "5.4. Thiết Kế Âm Thanh & Rung Phản Hồi (Audio & Haptics)")
    add_bullet(doc, "Âm thanh đánh/xóa X: ", "Tiếng 'tick' gỗ giòn tan, êm tai, tạo cảm giác xúc giác cơ học thỏa mãn.")
    add_bullet(doc, "Âm thanh đặt mèo đúng: ", "Hợp âm vui tươi kết hợp tiếng mèo kêu 'meow' trong trẻo, khích lệ cảm xúc người chơi.")
    add_bullet(doc, "Âm thanh thử sai: ", "Âm gõ trầm nhẹ nhàng, không chói tai, không mang tính trừng phạt nặng nề.")
    add_bullet(doc, "Nhạc chiến thắng (Victory Jingle): ", "Đoạn nhạc mộc ngắn dưới 2 giây mang giai điệu vui tươi, chúc mừng người chơi vượt qua thử thách.")

    # ==========================================
    # CHƯƠNG 6: KIẾN TRÚC KỸ THUẬT & CÔNG NGHỆ
    # ==========================================
    add_h1(doc, "CHƯƠNG 6: KIẾN TRÚC KỸ THUẬT & CÔNG NGHỆ (TECHNICAL ARCHITECTURE)")

    add_h2(doc, "6.1. Đánh Giá & Lựa Chọn Engine: Godot 4.x + GDScript")
    add_p(doc, 
          "Sau khi so sánh kỹ thuật giữa các nền tảng phổ biến (Phaser 3, Unity và Godot 4), đội ngũ kỹ thuật đã lựa chọn "
          "Godot 4.x (sử dụng GDScript) làm engine chính thức cho dự án với các lý do chiến lược:")
    add_bullet(doc, "Gọn nhẹ & Tối ưu: ", "Bản build xuất cho Android/iOS chỉ nặng dưới 30MB, khởi động tức thì dưới 1 giây, tiết kiệm pin tối đa.")
    add_bullet(doc, "Hệ thống UI chuyên dụng: ", "Hệ thống Control Node của Godot hỗ trợ layout màn hình dọc, safe area cho tai thỏ/dynamic island cực kỳ trực quan và mạnh mẽ.")
    add_bullet(doc, "Độc lập bản quyền: ", "Mã nguồn mở hoàn toàn (MIT License), không rủi ro phí bản quyền cài đặt (install fee) hay ràng buộc pháp lý thương mại.")

    add_h2(doc, "6.2. Mô Hình Phân Lớp Kiến Trúc (Decoupled Architecture)")
    add_p(doc, "Hệ thống mã nguồn được phân rã thành các module hoàn toàn độc lập, đảm bảo khả năng kiểm thử tự động:")
    add_bullet(doc, "Puzzle Core Module: ", "Module thuần logic, hoàn toàn không phụ thuộc vào Godot Scene hay Audio. Chịu trách nhiệm kiểm tra 4 quy tắc GR, chấm điểm TryCat và xác định điều kiện thắng.")
    add_bullet(doc, "Gesture & Session Controller: ", "Lớp tiếp nhận và lọc nhiễu cảm ứng, nhận diện cử chỉ (chạm đơn, rê kéo, chạm đôi 280ms) và quản lý khe Undo 1 bước.")
    add_bullet(doc, "Hint Engine: ", "Bộ suy luận hình thức runtime, phân tích các ứng viên theo S2/S3 từ trạng thái bàn cờ hiện tại và trả về danh sách chứng cứ trực quan.")
    add_bullet(doc, "Save Repository (An Toàn Crash): ", "Quản lý lưu trữ trạng thái với cơ chế ghi tệp nguyên tử (atomic write qua temp file). Tách biệt hoàn toàn giữa `progress.json` (tiến trình xuyên suốt) và `session.json` (lượt chơi hiện tại), đảm bảo nếu app bị tắt đột ngột thì dữ liệu người chơi không bao giờ bị hỏng.")

    add_h2(doc, "6.3. Tiêu Chuẩn Hiệu Năng & Ngân Sách Phần Cứng (Performance Budget)")
    add_p(doc, "Dự án đặt ra các chỉ số kỹ thuật bắt buộc để nghiệm thu bản build trên thiết bị di động mục tiêu:")
    add_bullet(doc, "Tốc độ khung hình (Frame Rate): ", "60 FPS ổn định tuyệt đối trên các dòng máy phổ thông (iPhone 8 trở lên, Android Snapdragon 660 / RAM 3GB).")
    add_bullet(doc, "Dung lượng bộ nhớ RAM/VRAM: ", "Mức tiêu thụ RAM không vượt quá 120MB trong suốt quá trình chơi.")
    add_bullet(doc, "Độ trễ cảm ứng (Input Latency): ", "Hiển thị preview dấu X trong khung hình đầu tiên (dưới 50ms); phản hồi đặt mèo đúng/sai dưới 100ms.")

    # ==========================================
    # CHƯƠNG 7: KẾ HOẠCH TRIỂN KHAI & CỘT MỐC
    # ==========================================
    add_h1(doc, "CHƯƠNG 7: KẾ HOẠCH TRIỂN KHAI & LỘ TRÌNH PHÁT TRIỂN (ROADMAP)")

    add_h2(doc, "7.1. Bốn Cột Mốc Triển Khai Chính (Milestones M0 .. M3)")
    
    milestone_headers = ["Mốc", "Tên cột mốc", "Mục tiêu & Đầu ra bàn giao", "Điều kiện nghiệm thu"]
    milestone_rows = [
        ["M0", "Proof of Concept (Spike)", 
         "Bàn cờ T01 chạy được trên Godot: Chạm đơn X tức thì, chạm đôi 280ms đặt mèo, kéo X liên hoàn, sprite mèo nhảy múa trên 6 vùng màu.", 
         "Đo đạc atlas texture, mức chiếm dụng VRAM, kiểm tra độ nhạy cử chỉ trên thiết bị Android/iOS thật."],
        ["M1", "Vertical Slice", 
         "Hoàn thiện luồng chơi hoàn chỉnh với 4 level đầu tiên, hệ thống Tutorial Level 1, đầy đủ 5 màn hình (Home, Puzzle, 2 Result, Help, Settings), cơ chế lưu session/progress.", 
         "Ít nhất 8/10 người chơi thử nghiệm lần đầu hiểu rõ các cử chỉ chạm/kéo/đôi và quy tắc dấu X đỏ khóa."],
        ["M2", "Content Complete", 
         "Tích hợp đủ 24 level chiến dịch gốc (gồm mốc 10 và mốc 20, 6 level cuối bắt buộc dùng S3), hoàn tất toàn bộ asset đồ họa và âm thanh gốc.", 
         "100% level vượt qua validator `--release`, mỗi level có ít nhất 1 biên bản giải thực tế không nhìn đáp án với ≥ 1 tim."],
        ["M3", "Release Candidate", 
         "Build hoàn thiện cho Android/iOS chơi offline mượt mà, vượt qua toàn bộ 57 tiêu chí kiểm thử trong GDD-07.", 
         "Đóng gói bản phát hành chính thức, sẵn sàng cho công tác phát hành."]
    ]
    create_styled_table(doc, milestone_headers, milestone_rows, col_widths=[0.8, 1.8, 2.7, 1.2])

    add_h2(doc, "7.2. Tiêu Chuẩn Hoàn Thành (Definition of Done - DoD)")
    add_bullet(doc, "1. Minh bạch mã nguồn & đặc tả: ", "Mọi tính năng hoàn thành đều phải gắn với mã định danh GDD (GR, UX, ART, TECH, LV) và vượt qua mã bài test QA tương ứng.")
    add_bullet(doc, "2. Đồng bộ hợp đồng dữ liệu: ", "Bất kỳ sự thay đổi nào về luật chơi, cách tính điểm hay định dạng JSON đều phải cập nhật đồng bộ trên GDD, dữ liệu mẫu và bộ kiểm thử tự động.")
    add_bullet(doc, "3. Bản quyền tuyệt đối: ", "Mọi asset (model, sprite, texture, SFX) đều phải có tài liệu chứng minh nguồn gốc nguyên bản 100%.")

    add_h2(doc, "7.3. Định Hướng Mở Rộng Sau Giai Đoạn MVP (Post-MVP Roadmap)")
    add_p(doc, 
          "Để đảm bảo sự thành công lâu dài và khả năng giữ chân người chơi (retention), kiến trúc của trò chơi đã được thiết kế sẵn sàng "
          "cho các gói tính năng mở rộng sau khi bản MVP đạt cổng chất lượng:")
    add_bullet(doc, "1. Tính năng Meta 'Vườn Mèo' (Cat Collection): ", 
               "Người chơi tích lũy tiền vàng qua các màn thắng để mở khóa các giống mèo mới (Mèo Tam Thể, Mèo Xiêm, Mèo Mướp, Mèo Ba Tư...). Mỗi chú mèo sở hữu ngoại hình và bộ diễn hoạt độc nhất.")
    add_bullet(doc, "2. Cơ chế Cứu Lượt (Revive System): ", 
               "Khi hết 3 tim, người chơi có thể lựa chọn dùng tiền vàng hoặc xem một video quảng cáo thưởng (Rewarded Video) để hồi sinh và tiếp tục ván đấu.")
    add_bullet(doc, "3. Mở rộng kích thước bàn cờ lên N=7 đến N=12: ", 
               "Thử thách đỉnh cao cho cộng đồng game thủ kỳ cựu với hệ thống 12 nhãn vùng A..L và các kỹ thuật suy luận siêu cấp (S4/S5).")
    add_bullet(doc, "4. Trình Sinh Màn Chơi Tự Động (Procedural Level Generator): ", 
               "Hệ sinh thái màn chơi vô tận được sinh tự động bằng thuật toán kết hợp kiểm định toán học, phục vụ tính năng 'Câu đố hàng ngày' (Daily Challenge).")

    # ==========================================
    # CHƯƠNG 8: QUẢN TRỊ RỦI RO & KẾT LUẬN
    # ==========================================
    add_h1(doc, "CHƯƠNG 8: QUẢN TRỊ RỦI RO & KẾT LUẬN (RISK & CONCLUSION)")

    add_h2(doc, "8.1. Ma Trận Quản Trị Rủi Ro Kỹ Thuật & Thiết Kế")

    risk_headers = ["Lĩnh vực rủi ro", "Mô tả rủi ro tiềm ẩn", "Mức độ", "Giải pháp phòng ngừa & Giảm thiểu"]
    risk_rows = [
        ["Cử chỉ cảm ứng (UX)", 
         "Người chơi bấm quá nhanh hoặc bị loạn giữa chạm đơn và chạm đôi, vô tình đặt nhầm mèo.", 
         "Cao", 
         "Thiết lập cửa sổ chạm đôi chuẩn 280ms, hiển thị preview dấu X ngay khung hình đầu tiên. Thử nghiệm thực tế trên 10 người dùng mới tại mốc M1 để tinh chỉnh."],
        ["Đồ họa & VRAM", 
         "Bộ sprite sheet render từ 3D chiếm quá nhiều bộ nhớ texture trên điện thoại cấu hình thấp.", 
         "Trung bình", 
         "Dùng chung 1 bộ atlas duy nhất cho mỗi giống mèo; màu vùng chỉ áp dụng trên nền ô; kiểm soát chặt kích thước atlas và đo đạc VRAM tại mốc M0."],
        ["Độ khó màn chơi", 
         "Các màn chơi S3 quá khó khiến người chơi nản lòng hoặc phải đoán mò.", 
         "Trung bình", 
         "Tất cả màn 19–24 đều phải có vết suy luận (trace) được máy kiểm tra; hệ thống Hint giải thích trực quan từng bước loại trừ logic."],
        ["Sở hữu trí tuệ (IP)", 
         "Nguy cơ khiếu nại bản quyền từ các tựa game cùng thể loại trên thị trường.", 
         "Nghiêm ngặt", 
         "Toàn bộ asset mỹ thuật, âm thanh, câu chữ và cấu hình 24 level đều được sáng tạo nguyên bản 100%, có lưu trữ file nguồn Blender và manifest bản quyền."]
    ]
    create_styled_table(doc, risk_headers, risk_rows, col_widths=[1.2, 2.1, 0.9, 2.3])

    add_h2(doc, "8.2. Lời Kết & Đề Xuất Phê Duyệt")
    add_p(doc, 
          "Dự án \"Vườn Mèo\" (ASOL-Game-02) sở hữu một bản thiết kế toàn diện, có cơ sở toán học vững chắc, định hướng thẩm mỹ ấm cúng và "
          "chiến lược công nghệ thông minh. Dự án đáp ứng đầy đủ cả hai yếu tố: Tính giải trí thư giãn đại chúng (nhờ hình tượng mèo cưng đáng yêu) "
          "và Tính kích thích trí tuệ lâu dài (nhờ cơ chế giải đố logic thuần khiết).")
    add_p(doc, 
          "Với việc toàn bộ tài liệu đặc tả GDD, bộ công cụ kiểm thử tự động (Python Validator) và kiến trúc hệ thống đã được chuẩn bị hoàn tất, "
          "đội ngũ thiết kế kính trình Ban Lãnh đạo phê duyệt báo cáo để chính thức triển khai gói công việc kỹ thuật đầu tiên (Mốc M0 / Gói A - Bootstrap Spike).")

    # Lưu tài liệu
    doc.save(output_path)
    print(f"Đã tạo thành công file Word tại: {output_path}")

if __name__ == "__main__":
    from pathlib import Path
    REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
    DEFAULT_OUTPUT = REPOSITORY_ROOT / "docs/reports/Bao_Cao_Y_Tuong_Va_Thiet_Ke_Game_Vuon_Meo.docx"
    target_file = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else DEFAULT_OUTPUT
    build_game_design_document(target_file)
