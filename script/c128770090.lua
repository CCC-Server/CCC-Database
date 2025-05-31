-- 포츈 레이디-스카 오브 허밍 버드 (② 효과 완전 교체본)
local s,id=GetID()
function s.initial_effect(c)
	--①: 패 1장 버리고 서치 (변경 없음)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost1)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.operation1)
	c:RegisterEffect(e1)

	--②: 묘지에서 제외 → 묘지의 포츈 레이디 1장 제외 → 그 몬스터만을 소재로 싱크로 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.cost2)
	e2:SetTarget(s.target2)
	e2:SetOperation(s.operation2)
	c:RegisterEffect(e2)
end

--=====================================================
--①: 패 1장 버림 → “포츈” 마함 1장 + 포츈 레이디 몬스터 1장 서치
--	(기존 코드와 동일)
--=====================================================
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(nil,tp,LOCATION_HAND,0,1,nil) 
	end
	Duel.DiscardHand(tp,nil,1,1,REASON_COST+REASON_DISCARD)
end

local special_codes = {
	[68663748]  = true,  -- 타임 패시지
	[20057949]  = true,  -- 운명만곡
	[72885174]  = true,
	[91407982]  = true,  -- 포츈 퓨처
	[94662235]  = true,  -- 포츈 비전
}
function s.filter1a(c)
	local code=c:GetCode()
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and code~=id
	   and c:IsSSetable()
	   and ( c:IsSetCard(0x31) or special_codes[code] )
end
function s.filter1b(c)
	return c:IsSetCard(0x31) and c:IsMonster() and c:IsAbleToHand()
end

function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter1a,tp,LOCATION_DECK,0,1,nil)
		   and Duel.IsExistingMatchingCard(s.filter1b,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end

function s.operation1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.filter1a,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g2=Duel.SelectMatchingCard(tp,s.filter1b,tp,LOCATION_DECK,0,1,1,nil)
		g1:Merge(g2)
		if #g1>0 then
			Duel.SendtoHand(g1,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g1)
		end
	end
end

--②: 묘지의 이 카드를 제외하고 발동할 수 있다.
--자신 필드의 "포츈 레이디" 몬스터 1장을 대상으로 하여,
--그 카드의 레벨을 1~8 중 임의의 수치로 변경할 수 있다.
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

function s.target2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.lvfilter(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.lvfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.lvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x31) and c:GetLevel()>0
end

function s.operation2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- 효과 텍스트 2번: 레벨 선택 프롬프트
	local lv=Duel.AnnounceLevel(tp,1,8)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetValue(lv)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end