from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
import hashlib
import uuid
from datetime import datetime
from pathlib import Path

app = Flask(__name__)
CORS(app)

# JSON 파일 경로
ACCOUNT_FILE = os.path.join(os.path.dirname(__file__), '../json/account.json')

def load_accounts():
    """계정 데이터 로드"""
    if os.path.exists(ACCOUNT_FILE):
        with open(ACCOUNT_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"accounts": []}

def save_accounts(data):
    """계정 데이터 저장"""
    os.makedirs(os.path.dirname(ACCOUNT_FILE), exist_ok=True)
    with open(ACCOUNT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def hash_password(password):
    """비밀번호 해싱"""
    return hashlib.sha256(password.encode()).hexdigest()

# ============ 인증 API ============

@app.route('/api/auth/signup', methods=['POST'])
def signup():
    """회원가입"""
    try:
        data = request.get_json()
        nickname = data.get('nickname', '').strip()
        password = data.get('password', '').strip()

        if not nickname or not password:
            return jsonify({'success': False, 'message': '닉네임과 비밀번호를 입력해주세요.'}), 400

        if len(password) < 6:
            return jsonify({'success': False, 'message': '비밀번호는 최소 6자 이상이어야 합니다.'}), 400

        accounts = load_accounts()
        
        # 중복 닉네임 확인
        if any(acc['nickname'] == nickname for acc in accounts['accounts']):
            return jsonify({'success': False, 'message': '이미 존재하는 닉네임입니다.'}), 400

        # 새 계정 생성
        new_account = {
            'id': str(uuid.uuid4()),
            'nickname': nickname,
            'password_hash': hash_password(password),
            'email': f'{nickname.lower()}@ratip.local',
            'gold': 0,
            'rank_id': 1,
            'avatar_url': None,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat()
        }
        
        accounts['accounts'].append(new_account)
        save_accounts(accounts)

        return jsonify({
            'success': True,
            'message': '✅ 계정이 생성되었습니다! 이제 로그인해주세요.',
            'user_id': new_account['id']
        }), 201

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    """로그인"""
    try:
        data = request.get_json()
        nickname = data.get('nickname', '').strip()
        password = data.get('password', '').strip()

        if not nickname or not password:
            return jsonify({'success': False, 'message': '닉네임과 비밀번호를 입력해주세요.'}), 400

        accounts = load_accounts()
        password_hash = hash_password(password)

        # 계정 찾기
        account = None
        for acc in accounts['accounts']:
            if acc['nickname'] == nickname and acc['password_hash'] == password_hash:
                account = acc
                break

        if not account:
            return jsonify({'success': False, 'message': '닉네임 또는 비밀번호가 일치하지 않습니다.'}), 401

        return jsonify({
            'success': True,
            'message': '로그인 성공',
            'user': {
                'id': account['id'],
                'nickname': account['nickname'],
                'email': account['email'],
                'gold': account['gold'],
                'rank_id': account['rank_id'],
                'avatar_url': account['avatar_url'],
                'created_at': account['created_at']
            }
        }), 200

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ============ 프로필 API ============

@app.route('/api/profile/<user_id>', methods=['GET'])
def get_profile(user_id):
    """프로필 조회"""
    try:
        accounts = load_accounts()
        
        for account in accounts['accounts']:
            if account['id'] == user_id:
                return jsonify({
                    'success': True,
                    'user': {
                        'id': account['id'],
                        'nickname': account['nickname'],
                        'email': account['email'],
                        'gold': account['gold'],
                        'rank_id': account['rank_id'],
                        'avatar_url': account['avatar_url'],
                        'created_at': account['created_at']
                    }
                }), 200

        return jsonify({'success': False, 'message': '사용자를 찾을 수 없습니다.'}), 404

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/api/profile/<user_id>', methods=['PUT'])
def update_profile(user_id):
    """프로필 업데이트"""
    try:
        data = request.get_json()
        accounts = load_accounts()

        for account in accounts['accounts']:
            if account['id'] == user_id:
                # 업데이트 가능한 필드들
                if 'avatar_url' in data:
                    account['avatar_url'] = data['avatar_url']
                if 'nickname' in data:
                    account['nickname'] = data['nickname']
                
                account['updated_at'] = datetime.now().isoformat()
                save_accounts(accounts)

                return jsonify({
                    'success': True,
                    'message': '프로필이 업데이트되었습니다.',
                    'user': account
                }), 200

        return jsonify({'success': False, 'message': '사용자를 찾을 수 없습니다.'}), 404

    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500

# ============ 상태 확인 ============

@app.route('/api/health', methods=['GET'])
def health():
    """헬스 체크"""
    return jsonify({'status': 'ok', 'message': 'RATIP Backend API is running'}), 200

@app.route('/', methods=['GET'])
def index():
    """루트"""
    return jsonify({'message': 'RATIP Backend API', 'version': '1.0.0'}), 200

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
