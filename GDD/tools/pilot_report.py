"""Offline editorial report and answer-free paper playtest sheets."""
import csv


def unit_name(unit):
    return (f"vùng {unit['id']}" if unit['type'] == 'region' else
            f"{'hàng' if unit['type'] == 'row' else 'cột'} {unit['id']+1}")


def explain(step):
    target = step['conclusion']
    if step['rule'] == 'S2':
        return f"{unit_name(step['focus'])} chỉ còn ô ({target['r']+1}, {target['c']+1}); đặt kẹo."
    cells = ', '.join(f"({p['r']+1}, {p['c']+1})" for p in target['cells'])
    return (f"Ứng viên của {unit_name(step['source'])} nằm trọn trong {unit_name(step['target'])}; "
            f"loại các ô {cells} khỏi {unit_name(step['target'])}.")


def blind_sheets(data):
    lines = ['# CanDoKu — Phiếu giải thử không có đáp án', '',
             'Mỗi hàng, cột và vùng chữ cái có đúng một kẹo; các kẹo không chạm nhau kể cả góc.',
             'Ký hiệu ● là kẹo cho sẵn. Ghi thêm kẹo và X bằng bút. Tọa độ (hàng, cột) bắt đầu từ 1.',
             'Phiếu giấy kiểm suy luận và đọc vùng; không kiểm cử chỉ, Hint hay UI của game.', '',
             'Người điều phối phát từng phiếu theo thứ tự được phân công. Không cho xem report.md hoặc levels.json.', '']
    for level in data['levels']:
        n = level['size']
        givens = {(g['r'], g['c']) for g in level['givens']}
        lines += [f"## {level['id']} — {n}×{n}", '', '| Hàng / Cột | ' + ' | '.join(str(c+1) for c in range(n)) + ' |',
                  '| --- | ' + ' | '.join('---' for _ in range(n)) + ' |']
        for r, row in enumerate(level['regions']):
            cells = [label + (' ●' if (r, c) in givens else ' ·') for c, label in enumerate(row)]
            lines.append('| ' + str(r+1) + ' | ' + ' | '.join(cells) + ' |')
        lines += ['', 'Mã người: ______  Vị trí trong buổi thử: ______', '',
                  'Thời gian giải (loại thời gian nghỉ): ______  Hoàn thành / bỏ cuộc: ______', '',
                  'Số lần cần trợ giúp: ______  Chỗ bị kẹt / vùng khó đọc: ____________________', '', '---', '']
    return '\n'.join(lines)


def editorial_report(data, report):
    lines = ['# Pilot sinh level CanDoKu', '',
             f"Kết quả máy: **{report['status']}**, {report['acceptedCount']}/{len(report['profile']['slots'])} màn; "
             f"{report['attempts']} ứng viên; {report['elapsedSeconds']} giây.", '',
             'Nhãn difficulty là tạm tính. Người chơi: NOT_RUN, 0 mẫu. UI/thiết bị: NOT_RUN.',
             'Order là vị trí dự kiến để kiểm logic band; pilot không phải campaign phát hành.', '',
             '| ID | Order | Cỡ | Given | Tier | S2 / S3 | Điểm | Min–max policy | Độ sâu | Nhãn tạm |',
             '| --- | ---: | --- | ---: | --- | --- | ---: | --- | ---: | --- |']
    for level, result in zip(data['levels'], report['levels']):
        vector = result['vector']
        counts, spread = vector['ruleCounts'], vector['policySpread']
        lines.append(f"| {level['id']} | {level['order']} | {level['size']}×{level['size']} | {len(level['givens'])} | "
                     f"{result['lowestProvenTier']} | {counts['S2']} / {counts['S3']} | {result['D_raw']} | "
                     f"{spread['min']}–{spread['max']} | {vector['proofDepth']} | {level['difficulty']} |")
    lines += ['', '## Phương pháp và giới hạn', '',
              'Điểm = S2 + 4×S3 + 2×số trạng thái chỉ còn một hành động + độ sâu chứng cứ + ceil(số ô chứng cứ lớn nhất/6).',
              'Duyệt S2 trước S3, gộp các kết luận giống nhau; phá hòa theo ít đơn vị/ô chứng cứ, loại nhiều ô rồi thứ tự cố định. '
              'Báo thêm hai policy theo tọa độ và tọa độ ngược. Không tuyên bố đường ngắn nhất.',
              'Độ sâu lấy từ cạnh phụ thuộc chứng cứ từng bước, gồm các loại trừ cần để tái hiện đầy đủ kết luận S3. '
              'Given/topology là gốc 0. Đây là đồ thị chứng cứ đã chọn, không phải độ sâu tối thiểu toàn cục.',
              'Ngưỡng easy ≤16 chỉ là giả thuyết; tier I luôn medium tạm. Điểm không dự đoán phút chơi.',
              'Vùng được sinh bằng tăng trưởng qua cạnh và kiểm liên thông độc lập. Chưa tối ưu mỹ thuật hoặc nhánh hẹp; '
              'regionAreas/boundaryEdges chỉ hỗ trợ biên tập.',
              'Loại trùng hình vùng trong toàn bộ batch và kho --exclude dưới xoay/lật/đổi nhãn; nghiêm hơn cửa sổ 8 màn.', '',
              '## Ứng viên bị loại', '']
    lines += [f'- {reason}: {count}' for reason, count in report['rejections'].items()]
    if report['unmetSlots']:
        lines += ['', f"Chưa đủ các slot: {report['unmetSlots']}"]
    lines += ['', '## Lời giải dành riêng cho người điều phối', '']
    for level, result in zip(data['levels'], report['levels']):
        lines += [f"### {level['id']}", '', f"Cờ cần review: {', '.join(result['reviewFlags']) or 'không có cờ tự động; vẫn cần duyệt người' }.", '']
        lines += [f'{i}. {explain(step)}' for i, step in enumerate(level['logicTrace'], 1)]
        lines += ['']
    lines += ['## Thử với người chơi', '',
              '1. Thử sớm 3–5 người để tìm lỗi hiểu luật; chưa đủ hiệu chỉnh thang độ khó.',
              '2. Hiệu chỉnh với ít nhất 10 người mục tiêu mỗi màn; dùng mã ẩn danh, đổi thứ tự màn giữa người chơi. '
              'Dạy S3 bằng ví dụ riêng trước khi thử nhóm S3 và ghi trình độ.',
              '3. Ghi cả bỏ cuộc và có trợ giúp vào playtests.csv; thời gian chỉ tính lúc giải, ghi riêng thời gian nghỉ.',
              '4. Báo tỷ lệ hoàn thành/trợ giúp, lỗi, median/p75 của nhóm hoàn thành không trợ giúp; '
              'nhóm còn lại báo riêng, không loại khỏi mẫu.',
              '5. So thứ hạng máy với dữ liệu trong cùng nhóm kỹ năng; chỉnh ngưỡng bằng tập hiệu chỉnh '
              'và kiểm lại bằng level chưa dùng. Phiếu giấy không thay lượt chơi thật trong client.', '',
              'Mỗi dòng CSV là một người–màn–lượt, ghi đúng revision và puzzleHash từ report.json. '
              'outcome: completed/abandoned; activeSeconds loại thời gian nghỉ; hints/mistakes là số thực đo. '
              'Không điền số 0 thay cho dữ liệu chưa đo. CSV mới chỉ có tiêu đề, chưa có kết quả người chơi.', '']
    return '\n'.join(lines)


def write_reports(folder, data, report):
    (folder / 'blind-playtest.md').write_text(blind_sheets(data), encoding='utf-8')
    (folder / 'report.md').write_text(editorial_report(data, report), encoding='utf-8')
    with (folder / 'playtests.csv').open('w', newline='', encoding='utf-8') as stream:
        csv.writer(stream).writerow(['participant', 'experience', 'revision', 'puzzleHash', 'levelId', 'position',
                                    'medium', 'activeSeconds', 'pauseSeconds', 'outcome', 'hints', 'mistakes', 'stuckStep', 'notes'])
