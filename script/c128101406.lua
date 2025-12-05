--Armed Dragon Nest
local s,id=GetID()
function s.initial_effect(c)
	--------------------------------
	-- ① 이 카드 발동시: "Armed Dragon" 몬스터 서치 (선택)
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- 이름이 같은 카드의 발동은 1턴에 1번
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② "Armed Dragon" 코스트로 GY로 간 카드 회수
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+100) -- ② 이름 있는 1턴 1번
	e2:SetCondition(s.gycon)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③ "Armed Dragon" 몬스터 파괴 대체
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id+200) -- ③ 이름 있는 1턴 1번
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

--------------------------------
-- 공용: "Armed Dragon" 세트 (0x111 가정)
--------------------------------
function s.adcard(c)
	return c:IsSetCard(0x111)
end

--------------------------------
-- ① 발동시 서치
--------------------------------
function s.thfilter(c)
	return s.adcard(c) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- 이 카드는 서치가 안 돼도 발동 가능해야 함 (선택 효과라서)
	if chk==0 then return true end
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then return end
	-- "You can add"라서 선택 여부
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------
-- ② "Armed Dragon" 몬스터 효과 발동 코스트로 GY로 간 카드 회수
-- 조건: 자신이 조종하는 "Armed Dragon" 몬스터의 효과 발동 코스트로 카드가 GY로 감
--------------------------------
function s.gyfilter(c,re)
	return c:IsLocation(LOCATION_GRAVE)
		and c:IsReason(REASON_COST)
		and c:GetReasonEffect()==re
		and c:IsAbleToHand()
end
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	if not re or not re:IsActivated() then return false end
	local rc=re:GetHandler()
	-- 자신이 조종하는 "Armed Dragon" 몬스터의 효과
	if rc:GetControler()~=tp or not s.adcard(rc) or not rc:IsType(TYPE_MONSTER) then
		return false
	end
	return eg:IsExists(s.gyfilter,1,nil,re)
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=eg:Filter(s.gyfilter,nil,re)
	if chkc then return g:IsContains(chkc) end
	if chk==0 then return #g>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=g:Select(tp,1,1,nil)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,sg,1,0,0)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end

--------------------------------
-- ③ 파괴 대체: "Armed Dragon" 몬스터를 지키기 위해 GY의 "Armed Dragon" 카드 제외
--------------------------------
-- 파괴될 수 있는 대상: 자신 필드의 앞면 "Armed Dragon" 몬스터
function s.repfilter(c,tp)
	return c:IsFaceup()
		and s.adcard(c)
		and c:IsType(TYPE_MONSTER)
		and c:IsControler(tp)
		and c:IsOnField()
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
end
-- 코스트로 제외할 카드: GY의 "Armed Dragon" 카드 (몬스터/마함 모두 가능)
function s.rmfilter(c)
	return s.adcard(c) and c:IsAbleToRemove()
end

-- 어느 카드의 파괴를 대체할 수 있는지 판정
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

-- 실제로 대체를 쓸지 여부 + 코스트 존재 체크
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- 이번에 파괴될 카드들(eg) 중에 내 "Armed Dragon" 몬스터가 있어야 하고,
		-- 묘지에 제외할 "Armed Dragon" 카드도 있어야 함
		return eg:IsExists(s.repfilter,1,nil,tp)
			and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	-- 대체 효과를 사용할지 선택
	return Duel.SelectYesNo(tp,aux.Stringid(id,2))
end

-- 대체 실행: GY에서 "Armed Dragon" 카드 1장 제외
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	end
end
