--G.Rock 로드
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,s.pfil1,nil,2,nil,nil,nil,nil,false,s.pfun1)
	
	-- ①: 이 카드를 특수 소환했을 경우, 또는 이 카드가 묘지로 보내졌을 경우
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_TO_GRAVE)
	c:RegisterEffect(e2)
	
	-- ②: 패를 1장 이 카드의 엑시즈 소재로 하고, 자신의 덱 / 묘지에서 "G.Rock" 몬스터 2장을 패에 넣는다(같은 속성은 1장까지).
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tar3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)
end

function s.pfil1(c,xc,st,p)
	return c:IsXyzLevel(xc,9) or c:IsRank(9)
end
function s.pfun1(g,tp,xc)
	return g:FilterCount(Card.IsXyzLevel,nil,xc,9)==#g or g:FilterCount(Card.IsRank,nil,9)==#g
end
function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DOUBLE_XYZ_MATERIAL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetValue(1)
		e1:SetOperation(function(e,c) return c:IsRank(9) end)
		tc:RegisterEffect(e1)
	end
end

-- ②번 효과용 G.Rock 몬스터 필터
function s.tfil3(c)
	return c:IsSetCard(0xfa6) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.tar3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		if not (c:IsType(TYPE_XYZ) and Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0) then return false end
		local g=Duel.GetMatchingGroup(s.tfil3,tp,LOCATION_DECK|LOCATION_GRAVE,0,nil)
		return aux.SelectUnselectGroup(g,e,tp,2,2,aux.dpcheck(Card.GetAttribute),0)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK|LOCATION_GRAVE)
end

function s.op3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- 1. 패를 1장 선택
	local handg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	if #handg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local sg_hand=handg:Select(tp,1,1,nil)
	
	-- 2. 패 1장을 이 카드의 엑시즈 소재로 충전 (문법 오류 수정 지점)
	if #sg_hand>0 then
		Duel.Overlay(c,sg_hand) -- 그룹 오버레이 시 뒤의 true 제거하여 순정 규격으로 연산
		
		-- 3. 덱 / 묘지 구역에서 유효한 G.Rock 몬스터 그룹 확보 후 속성이 다른 2장 서치
		local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.tfil3),tp,LOCATION_DECK|LOCATION_GRAVE,0,nil)
		if #g<2 then return end
		
		local sg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dpcheck(Card.GetAttribute),1,tp,HINTMSG_ATOHAND)
		if #sg==2 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end