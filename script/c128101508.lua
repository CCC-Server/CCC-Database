-- 위해의 역전
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 기재 ("가비지 로드", "No.92 위해신룡")
	s.listed_names={44682448, 97403510}

	-- 발동
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetHintTiming(0,TIMING_END_PHASE)
	c:RegisterEffect(e0)

	-- ①: 자신 필드의 "No.92 위해신룡"의 소재를 1개 제거하고 효과 선택 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

	-- ②: 자신 필드의 "하트 어스" 몬스터가 파괴될 경우, 대신 묘지의 "가비지 로드" 관련 몬스터 1장을 제외
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- 관련 카드 코드
local CARD_GARBAGE_LORD = 44682448
local CARD_NO_92 = 97403510

-- [안전한 확인 함수] 카드명 기재 여부 확인
function s.is_listed_safe(c,code)
	if not c then return false end
	if c.IsCodeListed and c:IsCodeListed(code) then return true end
	if c.listed_names then
		for _,v in ipairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end

-- ① 효과 코스트 필터: No.92(위해신룡)만 체크 (타입 체크 제외)
function s.costfilter(c,tp)
	return c:IsFaceup() and c:IsCode(CARD_NO_92) and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end

-- ① 효과 코스트 실행
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	-- [수정됨] tp를 인자로 전달하여 nil 오류 해결
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DEATTACHFROM)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	g:GetFirst():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ① 효과 Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil)
	local b2=Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)}, -- 제외 효과
		{b2,aux.Stringid(id,2)}) -- 효과 무효 효과
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_REMOVE)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
	else
		e:SetCategory(CATEGORY_DISABLE)
	end
end

-- ① 효과 Operation
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		-- 상대 필드의 카드 1장을 제외한다.
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end
	else
		-- 상대 필드의 모든 앞면 표시 몬스터의 효과를 무효로 한다.
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		local tc=g:GetFirst()
		while tc do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)
			tc=g:GetNext()
		end
	end
end

-- ② 효과: 파괴 대역 필터 (하트 어스 / 위해신 관련)
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
		and (c:IsCode(CARD_NO_92) or c:IsCode(23998625) or c:IsCode(1281014504) or c:IsCode(1281014505))
		and not c:IsReason(REASON_REPLACE)
end

-- ② 효과: 대역 코스트 필터 (묘지의 가비지 로드 관련)
function s.resfilter(c)
	return c:IsMonster() and (c:IsCode(CARD_GARBAGE_LORD) or s.is_listed_safe(c,CARD_GARBAGE_LORD)) and c:IsAbleToRemove()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp)
		and Duel.IsExistingMatchingCard(s.resfilter,tp,LOCATION_GRAVE,0,1,nil) end
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,3)) then
		return true
	end
	return false
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.resfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end