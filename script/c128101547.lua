-- 데드웨어 일반 마법 (임의 명칭: 데드웨어 인젝션)
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 덱에서 '데드웨어' 서치 (+ 상대 필드 '데드웨어' 컨트롤 탈취)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_CONTROL)
	e1:SetType(EFFECT_TYPE_ACTIVATE) -- 마법 카드 발동
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- ①② 어느 쪽이든 1개만 발동 가능 (공통 ID 사용)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 상대 소환 시 묘지에서 제외하고 패 털기 (한데스)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id) -- ①② 어느 쪽이든 1개만 발동 가능
	e2:SetCondition(s.hdcon)
	e2:SetCost(aux.bfgcost) -- 묘지의 이 카드를 제외
	e2:SetTarget(s.hdtg)
	e2:SetOperation(s.hdop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
end

-- ① 효과 로직: 서치 및 컨트롤 탈취
function s.thfilter(c)
	return c:IsSetCard(0xc55) and c:IsMonster() and c:IsAbleToHand()
end
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc55) and c:IsControlerCanBeChanged()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.cfilter(chkc) end
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	
	-- 상대 필드에 데드웨어가 있을 경우 대상을 지정할지 선택
	local g=Duel.GetMatchingGroup(s.cfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
		local sg=Duel.SelectTarget(tp,s.cfilter,tp,0,LOCATION_MZONE,1,1,nil)
		 Duel.SetOperationInfo(0,CATEGORY_CONTROL,sg,1,0,0)
	else
		-- 대상을 지정하지 않을 경우 Target 플래그 해제 (EDOPro 표준 방식)
		e:SetProperty(0)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- 덱에서 데드웨어 몬스터 서치
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		
		-- 대상을 지정했을 경우 추가로 컨트롤 탈취
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and tc:IsControler(1-tp) then
			Duel.BreakEffect()
			Duel.GetControl(tc,tp)
		end
	end
end

-- ② 효과 로직: 묘지 견제
function s.hdcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대(1-tp)가 소환했을 때
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.hdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local ac=Duel.AnnounceCard(tp)
	Duel.SetTargetParam(ac)
	e:SetLabel(ac)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,1-tp,1)
end
function s.hdop(e,tp,eg,ep,ev,re,r,rp)
	local ac=e:GetLabel()
	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #g==0 then return end
	
	-- 선언한 카드가 패에 있는지 확인
	local dg=g:Filter(Card.IsCode,nil,ac)
	if #dg>0 then
		-- 있다면 그 중 1장을 버림
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_DISCARD)
		local sg=dg:Select(1-tp,1,1,nil)
		Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
	else
		-- 없다면 패를 확인
		Duel.ConfirmCards(tp,g)
		Duel.ShuffleHand(1-tp)
	end
end