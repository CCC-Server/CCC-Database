-- 유네티스 오피드레션
local s,id=GetID()
function s.initial_effect(c)
	-- 링크 소환 설정
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,2,99,s.lcheck)
	
	-- ①: 엔드 페이즈까지 제외
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
	
	-- ②: 세로열 소환 제한 (지속 효과: 해당 턴에 소환된 유네티스 기준)
	-- 기존 DISABLE_FIELD에서 FORCE_MZONE으로 변경하여 소환만 제한함
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_FORCE_MZONE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1) -- 상대 플레이어에게 적용
	e2:SetValue(s.mzoneval)
	c:RegisterEffect(e2)
	
	-- ③: 빈 세로열 봉쇄 (유발 효과)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.colcon)
	e3:SetTarget(s.coltg)
	e3:SetOperation(s.colop)
	c:RegisterEffect(e3)
end
s.listed_series={0xc80}

-- [링크 소재]
function s.matfilter(c,lc,sumtype,tp)
	return c:IsType(TYPE_EFFECT,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0xc80)
end

-- [효과 ①]
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)~=0 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_PHASE+PHASE_END)
			e1:SetReset(RESET_PHASE+PHASE_END)
			e1:SetLabelObject(tc)
			e1:SetCountLimit(1)
			e1:SetOperation(s.retop)
			Duel.RegisterEffect(e1,tp)
		end
	end
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ReturnToField(e:GetLabelObject())
end

-- [효과 ②: 유네티스 세로열 상대 소환 제한]
function s.unetfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc80) and c:GetTurnID()==Duel.GetTurnCount() 
	   and (c:IsSummonType(SUMMON_TYPE_NORMAL) or c:IsSummonType(SUMMON_TYPE_SPECIAL))
end

function s.mzoneval(e,fp,rp,r)
	local tp=e:GetHandlerPlayer()
	local forbidden=0
	
	-- 이번 턴 소환된 유네티스 몬스터 확인
	local g=Duel.GetMatchingGroup(s.unetfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	
	for tc in aux.Next(g) do
		local seq=tc:GetSequence()
		local p=tc:GetControler()
		
		-- 유네티스의 세로열(Column) 인덱스 계산 (0~4)
		local col = -1
		if seq < 5 then col = seq
		elseif seq == 5 then col = 1 -- 엑스트라 존 (우) -> 1번 열
		elseif seq == 6 then col = 3 -- 엑스트라 존 (좌) -> 3번 열
		end
		
		if col ~= -1 then
			-- 상대 입장(fp)에서 소환 불가능한 시퀀스 계산
			local block_seq = -1
			if p == fp then 
				-- 상대 필드에 있는 유네티스라면, 그 유네티스가 있는 열(col)과 같은 위치
				block_seq = col
			else
				-- 내 필드(tp)에 있는 유네티스라면, 상대 입장에서 대칭되는 위치 (4 - col)
				block_seq = 4 - col
			end
			
			if block_seq >= 0 and block_seq <= 4 then
				forbidden = forbidden | (1 << block_seq)
			end
		end
	end
	
	-- 0xff(모든 존)에서 금지된 존(forbidden)을 뺀 값을 반환 (허용된 존 리턴)
	return 0xff & ~forbidden
end

-- [효과 ③: 빈 세로열 봉쇄]
function s.cfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xc80) and c:IsSummonType(SUMMON_TYPE_NORMAL) and c:IsControler(tp)
end
function s.colcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.coltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		for i=0,4 do
			if s.is_column_empty(i, tp) then return true end
		end
		return false
	end
end
function s.colop(e,tp,eg,ep,ev,re,r,rp)
	local filter_val = 0
	filter_val = filter_val | 0xff00 -- S/T존 선택 불가
	filter_val = filter_val | 0xffff0000 -- 상대 필드 선택 불가
	
	for i=0,4 do
		if not s.is_column_empty(i, tp) then
			filter_val = filter_val | (1 << i)
		end
	end
	
	if (filter_val & 0x1f) == 0x1f then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ZONE)
	local zone = Duel.SelectDisableField(tp, 1, LOCATION_MZONE, 0, filter_val)
	if zone == 0 then return end
	
	local col = math.log(zone, 2)
	local opp_col = 4 - col
	
	local dis_zone = 0
	dis_zone = dis_zone | (1 << col)        -- 자신 M존
	dis_zone = dis_zone | (1 << (col+8))    -- 자신 S존
	dis_zone = dis_zone | (1 << (16+opp_col)) -- 상대 M존
	dis_zone = dis_zone | (1 << (24+opp_col)) -- 상대 S존
	
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE_FIELD)
	e1:SetOperation(function() return dis_zone end)
	e1:SetReset(RESET_PHASE+PHASE_END, 2)
	Duel.RegisterEffect(e1,tp)
end

function s.is_column_empty(col, tp)
	if Duel.GetFieldCard(tp, LOCATION_MZONE, col) then return false end
	if Duel.GetFieldCard(tp, LOCATION_SZONE, col) then return false end
	local opp_col = 4 - col
	if Duel.GetFieldCard(1-tp, LOCATION_MZONE, opp_col) then return false end
	if Duel.GetFieldCard(1-tp, LOCATION_SZONE, opp_col) then return false end
	if col == 1 then
		if Duel.GetFieldCard(tp, LOCATION_MZONE, 5) then return false end
		if Duel.GetFieldCard(1-tp, LOCATION_MZONE, 6) then return false end
	elseif col == 3 then
		if Duel.GetFieldCard(tp, LOCATION_MZONE, 6) then return false end
		if Duel.GetFieldCard(1-tp, LOCATION_MZONE, 5) then return false end
	end
	return true
end